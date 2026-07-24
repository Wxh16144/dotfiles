-- super_right_click/super_right_click.lua
--
-- 超级右键：Cmd+Ctrl+1 在 Finder 中弹出增强操作菜单。
-- 根据选中内容自动切换：单文件 / 单文件夹 / 多文件 / 未选中（可新建）。

local logger = require("lib.logger").new("super_right_click", "info")

-- ============================================================
-- 配置
-- ============================================================

local cfg = require("super_right_click.config")

-- 过滤工具候选列表
local function filterInstalledTools(candidates)
    local installed = {}
    for category, list in pairs(candidates) do
        for _, tool in ipairs(list) do
            if hs.fs.attributes(tool.cmd) then
                installed[category] = installed[category] or {}
                table.insert(installed[category], tool)
            else
                logger.i(tool.title .. " 未安装，跳过")
            end
        end
    end
    return installed
end

local tools = filterInstalledTools(cfg.toolCandidates)

-- ============================================================
-- 模块注入
-- ============================================================

local module = {}
local hotkey = nil

local finder = require("super_right_click.finder")
local ops = require("super_right_click.operations")
local menuBuilder = require("super_right_click.menu")

ops.TERMINAL_APP = cfg.terminalApp
ops.EDITORS = tools
menuBuilder.finder = finder
menuBuilder.ops = ops
menuBuilder.EDITORS = tools

-- ============================================================
-- 最近复制偏好
-- ============================================================

local runtimePaths = require("lib.runtime_paths")
local LAST_COPY_FILE = runtimePaths.cacheDir("super_right_click") .. "/last_copy.json"

local function loadLastCopyKey()
    if not cfg.rememberLastCopy then return nil end
    local f = io.open(LAST_COPY_FILE, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(hs.json.decode, content)
    if ok and data and data.key then
        return data.key
    end
    return nil
end

local function saveLastCopyKey(key)
    if not cfg.rememberLastCopy then return end
    local f = io.open(LAST_COPY_FILE, "w")
    if f then
        f:write(hs.json.encode({key = key}))
        f:close()
        logger.d("已记录最近复制操作: " .. key)
    else
        logger.e("无法写入 last_copy.json: " .. LAST_COPY_FILE)
    end
end

menuBuilder.loadLastCopyKey = loadLastCopyKey

-- ============================================================
-- 菜单显示
-- ============================================================

local popupMenubar = nil

local function showMenu(menuItems)
    if not menuItems or #menuItems == 0 then return end

    if not popupMenubar then
        popupMenubar = hs.menubar.new()
        if not popupMenubar then
            logger.e("无法创建 menubar 对象")
            return
        end
    end

    if not popupMenubar:isInMenuBar() then
        popupMenubar:returnToMenuBar()
    end
    popupMenubar:setTitle("")

    -- 递归包装菜单项：延迟执行 + 清理 + 记录最近复制操作
    local function wrapItem(item)
        if item.title == "-" then return {title = "-"} end
        if item.menu then
            local sub = {}
            for _, s in ipairs(item.menu) do table.insert(sub, wrapItem(s)) end
            return {title = item.title, menu = sub}
        end
        if not item.fn then return nil end
        local fn = item.fn
        local copyKey = item.copyKey
        return {
            title = item.title,
            fn = function()
                if copyKey then saveLastCopyKey(copyKey) end
                hs.timer.doAfter(0.05, function()
                    local ok, err = pcall(fn)
                    if not ok then logger.e("操作失败: " .. tostring(err)) end
                end)
                hs.timer.doAfter(0.1, function()
                    if popupMenubar then pcall(function() popupMenubar:removeFromMenuBar() end) end
                end)
            end,
        }
    end

    local wrapped = {}
    for _, item in ipairs(menuItems) do
        local w = wrapItem(item)
        if w then table.insert(wrapped, w) end
    end

    popupMenubar:setMenu(wrapped)
    popupMenubar:popupMenu(hs.mouse.absolutePosition())

    if popupMenubar then
        pcall(function() popupMenubar:removeFromMenuBar() end)
    end
end

-- ============================================================
-- 触发
-- ============================================================

local function trigger()
    if not finder.isFinderActive() then return end
    local items, folderPath = finder.getSelection()
    showMenu(menuBuilder.build(items, folderPath))
end

-- ============================================================
-- 启停
-- ============================================================

function module.start()
    if hotkey then return end
    hotkey = hs.hotkey.new(cfg.hotkeyMods, cfg.hotkeyKey, trigger)
    hotkey:enable()
    logger.i("超级右键已启动  " .. table.concat(cfg.hotkeyMods, "+") .. "+" .. cfg.hotkeyKey)
end

function module.stop()
    if hotkey then
        hotkey:delete()
        hotkey = nil
    end
    logger.i("超级右键已停止")
end

return module
