-- super_right_click/menu.lua
--
-- 菜单构建模块：根据不同选中状态生成菜单项表。

local logger = require("lib.logger").new("super_right_click", "info")

-- 由主模块注入的外部依赖
local M = {}
M.finder = nil   -- require("super_right_click.finder")
M.ops = nil      -- require("super_right_click.operations")
M.EDITORS = nil  -- 已过滤的编辑器列表 { code = {...}, git = {...} }

-- 统计已安装工具总数
local function countTools()
    local n = 0
    if not M.EDITORS then return 0 end
    for _, list in pairs(M.EDITORS) do
        n = n + #list
    end
    return n
end

-- ============================================================
-- 通用辅助
-- ============================================================

local function sep()
    return {title = "-"}
end

-- ============================================================
-- 复制组
-- 一级菜单显示最近使用的复制操作，其余放入「📋 更多复制」子菜单。
-- 如果只有一个复制项，则直接显示，不创建子菜单。
-- ============================================================

-- 由主模块注入
M.loadLastCopyKey = function() return nil end

-- 辅助：从 items 列表中找出 key 匹配的一项
local function findRecent(items, key)
    if not key then return nil end
    for _, it in ipairs(items) do
        if it.copyKey == key then return it end
    end
    return nil
end

-- 辅助：复制项 → 菜单条目（取前 30 字符截断标题，避免过长）
local function asSubItem(it)
    return {title = it.title, fn = it.fn, copyKey = it.copyKey}
end

-- 通用函数：给定 items 列表（每一项有 title, fn, copyKey），生成菜单
-- 返回: { items_to_add_to_menu }
local function buildCopyGroup(items)
    if #items == 0 then return {} end

    -- 只有一个项：直接显示，不搞子菜单
    if #items == 1 then
        return { asSubItem(items[1]) }
    end

    -- 读最近使用的 key
    local recentKey = M.loadLastCopyKey()
    local recent = findRecent(items, recentKey)

    local result = {}

    -- 最近使用项放在第一位
    if recent then
        table.insert(result, asSubItem(recent))
    else
        -- 没有记录，默认用第一项
        table.insert(result, asSubItem(items[1]))
    end

    -- 子菜单：包含全部项
    local sub = {}
    for _, it in ipairs(items) do
        table.insert(sub, asSubItem(it))
    end
    table.insert(result, {title = "📋 更多复制", menu = sub})

    return result
end

--------------------------------------------------------------
-- 单文件复制项
--------------------------------------------------------------

local function copyItemsForFile(item)
    local path, name = item.path, item.name
    return {
        {title = "📋 复制完整路径", fn = function() M.ops.copyToClipboard(path) end, copyKey = "fullPath"},
        {title = "📋 复制文件名",   fn = function() M.ops.copyToClipboard(name) end, copyKey = "fileName"},
        {title = "📋 复制所在目录", fn = function() M.ops.copyToClipboard(M.finder.parentDir(path)) end, copyKey = "parentDir"},
        {title = "📋 复制为 Markdown 链接", fn = function() M.ops.copyToClipboard("[" .. name .. "](file://" .. path .. ")") end, copyKey = "markdownLink"},
        {title = "📋 复制为 file URI", fn = function() M.ops.copyToClipboard("file://" .. path) end, copyKey = "fileURI"},
        {title = "📋 复制文件内容", fn = function() M.ops.copyFileContent(path) end, copyKey = "fileContent"},
    }
end

--------------------------------------------------------------
-- 单文件夹复制项
--------------------------------------------------------------

local function copyItemsForFolder(item)
    local path, name = item.path, item.name
    return {
        {title = "📋 复制文件夹路径", fn = function() M.ops.copyToClipboard(path) end, copyKey = "folderPath"},
        {title = "📋 复制文件夹名",   fn = function() M.ops.copyToClipboard(name) end, copyKey = "folderName"},
        {title = "📋 复制上级目录",   fn = function() M.ops.copyToClipboard(M.finder.parentDir(path)) end, copyKey = "folderParent"},
    }
end

--------------------------------------------------------------
-- 多选复制项
--------------------------------------------------------------

local function copyItemsForMulti(items)
    return {
        {title = string.format("📋 复制 %d 个路径（换行）", #items), fn = function()
            local t = {}
            for _, it in ipairs(items) do table.insert(t, it.path) end
            M.ops.copyToClipboard(table.concat(t, "\n"))
        end, copyKey = "multiPaths"},
        {title = string.format("📋 复制 %d 个文件名（换行）", #items), fn = function()
            local t = {}
            for _, it in ipairs(items) do table.insert(t, it.name) end
            M.ops.copyToClipboard(table.concat(t, "\n"))
        end, copyKey = "multiNames"},
    }
end

--------------------------------------------------------------
-- 未选中时复制项
--------------------------------------------------------------

local function copyItemsForEmpty(folderPath)
    return {
        {title = "📋 复制当前目录路径", fn = function() M.ops.copyToClipboard(folderPath) end, copyKey = "dirPath"},
    }
end

-- 对外：将复制组追加到菜单
local function appendCopyGroup(menu, items)
    for _, it in ipairs(buildCopyGroup(items)) do
        table.insert(menu, it)
    end
end

-- ============================================================
-- 工具打开组
-- ============================================================

-- 根据分类和数量自动构建工具子菜单。
-- code 类：直接用文件路径；git 类：用仓库根路径，且仅在 git 仓库中显示。
local function appendToolMenu(menu, path, contextDir, label)
    if countTools() == 0 then return end

    -- code 类工具：直接用 path
    -- git 类工具：查仓库根，不在 git 仓库中则跳过
    local isGit = contextDir and M.finder.isGitRepo(contextDir)
    local gitRoot = isGit and M.finder.findGitRoot(contextDir) or nil

    -- 收集所有可用工具（按分类顺序）
    local tools = {}
    local categoryOrder = {"code", "git"}
    for _, cat in ipairs(categoryOrder) do
        if M.EDITORS[cat] and #M.EDITORS[cat] > 0 then
            if cat == "git" and not gitRoot then
                goto nextCategory
            end
            for _, tool in ipairs(M.EDITORS[cat]) do
                -- git 工具用仓库根路径，code 工具用文件路径
                local toolPath = (cat == "git") and gitRoot or path
                local icon = (cat == "git") and "🔀 " or "📝 "
                table.insert(tools, {
                    title = icon .. tool.title,
                    fn = function() M.ops.openWithTool(tool, toolPath) end,
                })
            end
        end
        ::nextCategory::
    end

    if #tools == 0 then return end

    if #tools == 1 then
        -- 只有一个工具：直接显示（去掉 icon 前缀，title 已含）
        local t = tools[1]
        table.insert(menu, {title = t.title, fn = t.fn})
    else
        -- 多个工具：二级菜单，分类间用分隔线
        local subItems = {}
        local first = true
        for _, cat in ipairs(categoryOrder) do
            if M.EDITORS[cat] and #M.EDITORS[cat] > 0 then
                if cat == "git" and not gitRoot then
                    goto nextCat
                end
                if not first then
                    table.insert(subItems, {title = "-"})
                end
                first = false
                local icon = (cat == "git") and "🔀 " or "📝 "
                for _, tool in ipairs(M.EDITORS[cat]) do
                    local toolPath = (cat == "git") and gitRoot or path
                    table.insert(subItems, {
                        title = icon .. tool.title,
                        fn = function() M.ops.openWithTool(tool, toolPath) end,
                    })
                end
            end
            ::nextCat::
        end
        table.insert(menu, {title = "📂 用工具打开 " .. label, menu = subItems})
    end
end

-- ============================================================
-- 打开方式组
-- ============================================================

local function appendOpenGroupForFile(menu, path)
    local dir = M.finder.parentDir(path)
    table.insert(menu, sep())
    table.insert(menu, {title = "💻 在终端打开所在目录", fn = function() M.ops.openInTerminal(dir) end})
    appendToolMenu(menu, path, dir, M.finder.folderName(dir))
end

local function appendOpenGroupForFolder(menu, path)
    table.insert(menu, sep())
    table.insert(menu, {title = "💻 在终端打开", fn = function() M.ops.openInTerminal(path) end})
    appendToolMenu(menu, path, path, M.finder.folderName(path))
    table.insert(menu, {title = "🔍 在 Finder 中定位", fn = function() M.ops.revealInFinder(path) end})
end

local function appendOpenGroupForMulti(menu, items)
    local first = items[1].path
    local dir = M.finder.parentDir(first)
    table.insert(menu, sep())
    table.insert(menu, {title = "💻 在终端打开（首个文件目录）", fn = function() M.ops.openInTerminal(first) end})
    appendToolMenu(menu, first, dir, M.finder.folderName(dir))
end

local function appendOpenGroupForEmpty(menu, folderPath)
    table.insert(menu, sep())
    table.insert(menu, {title = "💻 在终端打开", fn = function() M.ops.openInTerminal(folderPath) end})
    appendToolMenu(menu, folderPath, folderPath, M.finder.folderName(folderPath))
end

-- ============================================================
-- 新建组
-- 出现规则：未选中时在 Finder 当前目录；选中单文件时在其所在目录；
-- 选中单文件夹时在该文件夹内；多选时在首个文件的所在目录。
-- ============================================================

local function appendNewGroupForFile(menu, path)
    local dir = M.finder.parentDir(path)
    local label = M.finder.folderName(dir)
    table.insert(menu, sep())
    table.insert(menu, {title = "📁 在 " .. label .. " 中新建...", fn = function() M.ops.promptNew(dir) end})
end

local function appendNewGroupForFolder(menu, path)
    local label = M.finder.folderName(path)
    table.insert(menu, sep())
    table.insert(menu, {title = "📁 在 " .. label .. " 中新建...", fn = function() M.ops.promptNew(path) end})
end

-- ============================================================
-- 组合完整菜单
-- ============================================================

function M.build(items, folderPath)
    local menu = {}

    if items and #items == 1 then
        local it = items[1]
        if M.finder.isDirectory(it.path) then
            appendCopyGroup(menu, copyItemsForFolder(it))
            appendOpenGroupForFolder(menu, it.path)
            appendNewGroupForFolder(menu, it.path)
        else
            appendCopyGroup(menu, copyItemsForFile(it))
            appendOpenGroupForFile(menu, it.path)
            appendNewGroupForFile(menu, it.path)
        end
    elseif items and #items > 1 then
        appendCopyGroup(menu, copyItemsForMulti(items))
        appendOpenGroupForMulti(menu, items)
        appendNewGroupForFile(menu, items[1].path)
    elseif folderPath then
        appendCopyGroup(menu, copyItemsForEmpty(folderPath))
        appendOpenGroupForEmpty(menu, folderPath)
        appendNewGroupForFolder(menu, folderPath)
    else
        return nil
    end

    return menu
end

return M
