-- presentation_mode/presentation_mode.lua
--
-- 一键进入/退出录制演示模式：隐藏桌面文件和桌面小组件。

local HOTKEY_MODS = {"ctrl", "alt", "cmd"}
local HOTKEY_KEY = "P"
local runtimePaths = require "lib.runtime_paths"

-- 只刷新显式声明了 refresh 的设置项；不需要即时生效的设置可以省略 refresh。
local REFRESH_ON_TOGGLE = true

-- state.json 只在演示模式开启期间存在，用来标记重载后仍处于演示模式。
local STATE_PATH = runtimePaths.stateFile("presentation_mode", "state.json")

-- enabledValue/disabledValue 分别对应进入/退出演示模式；不同 key 的布尔语义不一致。
-- refresh 可省略或设为空表，表示切换时只写 defaults，不重启相关系统进程。
local DEFAULT_SETTINGS = {
    {
        id = "finderCreateDesktop",
        displayName = "桌面文件",
        domain = "com.apple.finder",
        key = "CreateDesktop",
        -- true=显示，false=隐藏
        enabledValue = false,
        disabledValue = true,
        refresh = {"finder"},
    },
    {
        id = "windowManagerStandardHideWidgets",
        displayName = "桌面小组件",
        domain = "com.apple.WindowManager",
        key = "StandardHideWidgets",
        -- true=隐藏，false=显示
        enabledValue = true,
        disabledValue = false,
        -- refresh = {"dock", "systemUIServer"},
    },
    {
        id = "windowManagerStageManagerHideWidgets",
        displayName = "Stage Manager 小组件",
        domain = "com.apple.WindowManager",
        key = "StageManagerHideWidgets",
        -- true=隐藏，false=显示
        enabledValue = true,
        disabledValue = false,
        -- refresh = {"dock", "systemUIServer"},
    },
}

local logger = require("lib.logger").new("presentation_mode", "info")

local active = false
local menubar = nil
local hotkey = nil
local presentationMode = nil

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        logger.e("ERROR: " .. tostring(result))
        return false, result
    end

    return true, result
end

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function shellQuote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function runCommand(command)
    local output, ok, _, rc = hs.execute(command, true)
    output = output or ""

    if not ok then
        logger.w(string.format("命令执行失败(%s): %s", tostring(rc), command))
        if trim(output) ~= "" then
            logger.w(trim(output))
        end
    end

    return ok, output, rc
end

local function readFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function writeFile(path, content)
    local file, err = io.open(path, "w")
    if not file then
        logger.e("写入文件失败: " .. tostring(err))
        return false
    end

    file:write(content)
    file:close()
    return true
end

local function deleteFile(path)
    os.remove(path)
end

local function readModeMarker()
    local content = readFile(STATE_PATH)
    if not content or trim(content) == "" then
        return nil
    end

    local ok, decoded = pcall(function()
        return hs.json.decode(content)
    end)

    if ok and type(decoded) == "table" then
        return decoded
    end

    logger.w("演示模式状态文件无法解析")
    return nil
end

local function writeModeMarker(state)
    return writeFile(STATE_PATH, hs.json.encode(state, true))
end

local function writeDefault(setting, value)
    local command = table.concat({
        "defaults write",
        shellQuote(setting.domain),
        shellQuote(setting.key),
        "-bool",
        value and "true" or "false",
    }, " ")

    return runCommand(command)
end

local function refreshFinder()
    runCommand("killall Finder")
end

local function refreshDock()
    runCommand("killall Dock")
end

local function refreshSystemUIServer()
    runCommand("killall SystemUIServer")
end

local function markRefreshTargets(changedTargets, refreshTargets)
    if type(refreshTargets) == "string" then
        changedTargets[refreshTargets] = true
        return
    end

    for _, refreshTarget in ipairs(refreshTargets or {}) do
        changedTargets[refreshTarget] = true
    end
end

local function refreshChangedTargets(changedTargets)
    if changedTargets.finder then
        refreshFinder()
    end

    if changedTargets.dock then
        refreshDock()
    end

    if changedTargets.systemUIServer then
        refreshSystemUIServer()
    end
end

local function applyPresentationDefaults(shouldRefresh)
    local changedTargets = {}

    for _, setting in ipairs(DEFAULT_SETTINGS) do
        local ok = writeDefault(setting, setting.enabledValue)
        if ok and shouldRefresh then
            markRefreshTargets(changedTargets, setting.refresh)
        end
    end

    if shouldRefresh then
        refreshChangedTargets(changedTargets)
    end
end

local function restorePresentationDefaults(shouldRefresh)
    local changedTargets = {}

    for _, setting in ipairs(DEFAULT_SETTINGS) do
        local ok = writeDefault(setting, setting.disabledValue)
        if ok then
            logger.i(string.format("退出演示模式，恢复%s为 %s", setting.displayName, tostring(setting.disabledValue)))
        end

        if ok and shouldRefresh then
            markRefreshTargets(changedTargets, setting.refresh)
        end
    end

    if shouldRefresh then
        refreshChangedTargets(changedTargets)
    end
end

local function updateMenubar()
    if not menubar then
        return
    end

    menubar:setTitle(active and "🎬 演示中" or "🎬 演示")
end

local function buildMenu()
    return {
        {
            title = active and "✅ 退出演示" or "🎬 进入演示",
            fn = function()
                safeCall(function()
                    if active then
                        presentationMode.disable()
                    else
                        presentationMode.enable()
                    end
                end)
            end,
        },
        {
            title = "🧹 修复显示（刷新一次）",
            fn = function()
                safeCall(function()
                    presentationMode.refreshDisplay()
                end)
            end,
        },
        {title = "-"},
        {
            title = "⌨️ ⌃⌥⌘P",
            disabled = true,
        },
    }
end

local function loadSavedState()
    local modeMarker = readModeMarker()

    if modeMarker and modeMarker.active then
        active = true
        logger.i("检测到未恢复的演示模式状态")
    end
end

local function showStatus(message)
    hs.alert.show(message, 3)
    logger.i(message)
end

local function enablePresentationMode()
    if active then
        showStatus("演示模式已开启")
        return
    end

    -- 先写入状态文件，再改系统设置；即使 Hammerspoon 中途重载，菜单也能继续显示当前状态。
    local state = {
        active = true,
        startedAt = os.date("%Y-%m-%d %H:%M:%S"),
    }

    writeModeMarker(state)
    applyPresentationDefaults(REFRESH_ON_TOGGLE)
    active = true
    updateMenubar()
    showStatus("已进入演示模式")
end

local function disablePresentationMode()
    restorePresentationDefaults(REFRESH_ON_TOGGLE)

    active = false
    deleteFile(STATE_PATH)
    updateMenubar()
    showStatus("已退出演示模式并显示桌面和小组件")
end

local function refreshDisplay()
    if active then
        applyPresentationDefaults(true)
        showStatus("已刷新演示模式显示")
        return
    end

    restorePresentationDefaults(true)
    deleteFile(STATE_PATH)
    showStatus("已刷新桌面和小组件显示")
end

local function setupMenubar()
    if menubar then
        menubar:delete()
        menubar = nil
    end

    menubar = hs.menubar.new()
    if menubar then
        menubar:setMenu(buildMenu)
        updateMenubar()
    end
end

local function setupHotkey()
    if hotkey then
        hotkey:delete()
        hotkey = nil
    end

    hotkey = hs.hotkey.bind(HOTKEY_MODS, HOTKEY_KEY, function()
        safeCall(function()
            presentationMode.toggle()
        end)
    end)
end

presentationMode = {
    start = function()
        loadSavedState()
        setupMenubar()
        setupHotkey()
        logger.i("演示模式已加载")
    end,

    stop = function()
        if hotkey then
            hotkey:delete()
            hotkey = nil
        end

        if menubar then
            menubar:delete()
            menubar = nil
        end

        logger.i("演示模式已停止")
    end,

    enable = function()
        enablePresentationMode()
    end,

    disable = function()
        disablePresentationMode()
    end,

    restore = function()
        disablePresentationMode()
    end,

    forceShow = function()
        restorePresentationDefaults(true)
        active = false
        deleteFile(STATE_PATH)
        updateMenubar()
        showStatus("已强制显示桌面和小组件")
    end,

    refreshDisplay = function()
        refreshDisplay()
    end,

    toggle = function()
        if active then
            disablePresentationMode()
        else
            enablePresentationMode()
        end
    end,

    isEnabled = function()
        return active
    end,
}

return presentationMode