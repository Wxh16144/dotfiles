-- super_right_click/operations.lua
--
-- 操作函数层：复制、打开、新建等具体操作。

local logger = require("lib.logger").new("super_right_click", "info")

local M = {}

-- 终端应用（由主模块注入）
M.TERMINAL_APP = "iTerm2"

-- 编辑器列表（由主模块注入）
M.EDITORS = {}

-- ============================================================
-- 剪贴板 & 文件操作
-- ============================================================

function M.copyToClipboard(text)
    hs.pasteboard.setContents(text)
    hs.alert.show("✅ 已复制", 0.8)
end

function M.copyFileContent(path)
    local f = io.open(path, "r")
    if not f then
        hs.alert.show("❌ 无法读取文件", 2)
        return
    end
    local content = f:read("*a")
    f:close()
    hs.pasteboard.setContents(content)
    hs.alert.show("✅ 已复制文件内容", 0.8)
end

-- ============================================================
-- 打开方式
-- ============================================================

function M.openInTerminal(path)
    local finder = require("super_right_click.finder")
    local dir = finder.isDirectory(path) and path or finder.parentDir(path)
    local escaped = dir:gsub(" ", "\\ ")

    if M.TERMINAL_APP == "iTerm2" then
        hs.osascript.applescript(string.format([[
            tell application "iTerm2"
                if (count of windows) = 0 then
                    create window with default profile
                end if
                tell current session of current window
                    write text "cd %s && clear"
                end tell
                activate
            end tell
        ]], escaped))
    else
        hs.osascript.applescript(string.format([[
            tell application "Terminal"
                activate
                do script "cd %s && clear"
            end tell
        ]], escaped))
    end
end

function M.openWithTool(editor, path)
    local args = editor.args or {}
    local allArgs = {}
    for _, a in ipairs(args) do table.insert(allArgs, a) end
    table.insert(allArgs, path)
    hs.task.new(editor.cmd, function(exitCode)
        if exitCode ~= 0 then
            hs.alert.show("❌ " .. editor.title .. " 打开失败", 2)
        end
    end, allArgs):start()
end

function M.revealInFinder(path)
    hs.osascript.applescript(string.format([[
        tell application "Finder"
            activate
            reveal (POSIX file "%s")
        end tell
    ]], path))
end

local function quarantineResult(exitCode, stdOut, stdErr)
    local output = (stdOut or "") .. (stdErr or "")
    if exitCode == 0 then return "success", output end
    if output:match("No such xattr") then return "missing", output end
    if output:match("Permission denied") or output:match("Operation not permitted") then
        return "permission", output
    end
    return "error", output
end

local function showQuarantineResult(result, output)
    if result == "success" then
        hs.alert.show("✅ 已移除隔离属性", 1)
    elseif result == "missing" then
        hs.alert.show("ℹ️ 无需处理", 1)
    else
        logger.e("移除隔离属性失败: " .. tostring(output))
        hs.alert.show("❌ 移除隔离属性失败", 2)
    end
end

local function removeQuarantineWithPrivileges(path)
    local script = [[
on run argv
    set appPath to item 1 of argv
    do shell script "/usr/bin/xattr -r -d com.apple.quarantine " & quoted form of appPath with administrator privileges
end run
]]
    local task = hs.task.new("/usr/bin/osascript", function(exitCode, stdOut, stdErr)
        local output = (stdOut or "") .. (stdErr or "")
        if exitCode ~= 0 and (output:match("User canceled") or output:match("%-128")) then
            hs.alert.show("已取消管理员授权", 1)
            return
        end
        local result, detail = quarantineResult(exitCode, stdOut, stdErr)
        showQuarantineResult(result, detail)
    end, {"-e", script, path})

    if not task or not task:start() then
        logger.e("无法启动管理员授权任务")
        hs.alert.show("❌ 无法请求管理员授权", 2)
    end
end

local function removeQuarantine(path)
    local task = hs.task.new("/usr/bin/xattr", function(exitCode, stdOut, stdErr)
        local result, output = quarantineResult(exitCode, stdOut, stdErr)
        if result == "permission" then
            removeQuarantineWithPrivileges(path)
            return
        end
        showQuarantineResult(result, output)
    end, {"-r", "-d", "com.apple.quarantine", path})

    if not task or not task:start() then
        logger.e("无法启动 xattr 任务")
        hs.alert.show("❌ 无法执行隔离属性清理", 2)
    end
end

function M.removeQuarantine(path)
    local task = hs.task.new("/usr/bin/xattr", function(exitCode, stdOut)
        if exitCode == 0 and not (stdOut or ""):match("com%.apple%.quarantine") then
            showQuarantineResult("missing", "")
            return
        end
        removeQuarantine(path)
    end, {"-r", path})

    if not task or not task:start() then
        logger.e("无法启动 xattr 检查任务")
        hs.alert.show("❌ 无法检查隔离属性", 2)
    end
end

-- ============================================================
-- 新建
-- ============================================================

local function createNew(parentFolder, name)
    local fullPath = parentFolder .. "/" .. name
    local trimmed = name:gsub("/+$", "")
    local hasExt = trimmed:match("%.[%w]+$") ~= nil

    if hasExt then
        local pd = fullPath:match("(.*)/")
        if pd then
            hs.execute("/bin/mkdir -p " .. pd:gsub(" ", "\\ "))
        end
        hs.execute("/usr/bin/touch " .. fullPath:gsub(" ", "\\ "))
        hs.alert.show("✅ 已创建文件: " .. trimmed, 1)
    else
        hs.execute("/bin/mkdir -p " .. fullPath:gsub(" ", "\\ "))
        hs.alert.show("✅ 已创建文件夹: " .. trimmed, 1)
    end
end

function M.promptNew(folderPath)
    local cleanPath = folderPath:gsub("/+$", "")
    local shortName = cleanPath:match("([^/]+)$") or "当前目录"
    local script = string.format([[
        display dialog "在 %s 中新建:" default answer "untitled" with title "新建" buttons {"取消", "创建"} default button "创建"
        set theResult to result
        return (button returned of theResult) & "|||" & (text returned of theResult)
    ]], shortName)
    local ok, result = hs.osascript.applescript(script)
    if not ok then
        logger.e("AppleScript 弹窗失败: " .. tostring(result))
        return
    end
    local raw = type(result) == "table" and table.concat(result, "\n") or result
    local button, text = raw:match("^(.*)|||(.*)$")
    if button == "创建" and text and text ~= "" then
        createNew(folderPath, text)
    end
end

return M
