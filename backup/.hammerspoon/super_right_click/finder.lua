-- super_right_click/finder.lua
--
-- Finder 交互层：检测选中项、当前窗口目录。

local logger = require("lib.logger").new("super_right_click", "info")

local M = {}

-- 提取路径末尾的文件夹名
function M.folderName(p)
    local clean = p:gsub("/+$", "")
    return clean:match("([^/]+)$") or p
end

-- Finder 是否在前台
function M.isFinderActive()
    local app = hs.application.frontmostApplication()
    return app and app:bundleID() == "com.apple.finder"
end

-- AppleScript：获取选中项，无选中时回退到当前窗口目录
local GET_SELECTION_SCRIPT = [[
tell application "Finder"
    set selectedItems to selection
    if (count of selectedItems) = 0 then
        try
            set targetFolder to (POSIX path of (target of front window as alias))
            return "FOLDER:" & targetFolder
        on error
            return ""
        end try
    end if
    set output to ""
    repeat with i from 1 to count of selectedItems
        set thisItem to item i of selectedItems
        set itemPath to POSIX path of (thisItem as alias)
        set itemName to name of thisItem
        set output to output & itemName & "|||" & itemPath & "|||"
        if i < count of selectedItems then
            set output to output & "^^^"
        end if
    end repeat
    return output
end tell
]]

-- 解析 AppleScript 返回值
local function parseSelection(raw)
    if not raw or raw == "" then return nil, nil end
    if raw:match("^FOLDER:") then
        return nil, raw:sub(8)
    end
    local items = {}
    for chunk in raw:gmatch("([^%^%^%^]+)") do
        local name, path = chunk:match("^([^|]+)|||(.*)|||$")
        if name and path then
            table.insert(items, {name = name, path = path})
        end
    end
    return #items > 0 and items or nil, nil
end

-- 获取 Finder 选中项
-- 返回：items (table of {name, path}), folderPath (string or nil)
function M.getSelection()
    local ok, result = hs.osascript.applescript(GET_SELECTION_SCRIPT)
    if not ok then
        logger.e("AppleScript 失败: " .. tostring(result))
        return nil, nil
    end
    local raw = type(result) == "table" and table.concat(result, "\n") or result
    return parseSelection(raw)
end

-- 判断路径是否为目录
function M.isDirectory(path)
    local attr = hs.fs.attributes(path)
    return attr and attr.mode == "directory"
end

-- 获取文件/目录的父目录路径
function M.parentDir(filePath)
    return filePath:match("(.*)/") or filePath
end

-- 判断路径是否在 Git 仓库中（向上查找 .git）
function M.isGitRepo(path)
    -- 找到实际的目录（文件取其父目录）
    local dir = M.isDirectory(path) and path or M.parentDir(path)
    -- 向上逐级查找 .git
    local current = dir
    for _ = 1, 20 do
        if hs.fs.attributes(current .. "/.git") then
            return true
        end
        local parent = current:match("(.*)/")
        if not parent or parent == current then break end
        current = parent
    end
    return false
end

-- 在 Git 仓库中向上查找 .git 所在目录（即仓库根）
function M.findGitRoot(path)
    local dir = M.isDirectory(path) and path or M.parentDir(path)
    local current = dir
    for _ = 1, 20 do
        if hs.fs.attributes(current .. "/.git") then
            return current
        end
        local parent = current:match("(.*)/")
        if not parent or parent == current then break end
        current = parent
    end
    return nil
end

return M
