-- presentation_mode/presentation_mode.lua
--
-- 一键进入/退出录制演示模式：隐藏桌面图标和桌面小组件。
--
-- 全部设置项都写在 com.apple.WindowManager，改完立即生效，不需要 kill 任何系统进程。

local HOTKEY_MODS = {"ctrl", "alt", "cmd"}
local HOTKEY_KEY = "P"
local runtimePaths = require "lib.runtime_paths"

-- state.json 只在演示模式开启期间存在，用来标记重载后仍处于演示模式。
local STATE_PATH = runtimePaths.stateFile("presentation_mode", "state.json")

-- enabledValue/disabledValue 分别对应进入/退出演示模式；不同 key 的布尔语义不一致。
-- 这些键都支持热更新，写入即生效，所以不需要刷新任何系统进程。
local DEFAULT_SETTINGS = {
    {
        id = "standardHideDesktopIcons",
        displayName = "桌面图标",
        domain = "com.apple.WindowManager",
        key = "StandardHideDesktopIcons",
        -- true=隐藏，false=显示
        enabledValue = true,
        disabledValue = false,
    },
    {
        id = "standardHideWidgets",
        displayName = "桌面小组件",
        domain = "com.apple.WindowManager",
        key = "StandardHideWidgets",
        -- true=隐藏，false=显示
        enabledValue = true,
        disabledValue = false,
    },
    {
        id = "stageManagerHideWidgets",
        displayName = "Stage Manager 小组件",
        domain = "com.apple.WindowManager",
        key = "StageManagerHideWidgets",
        -- true=隐藏，false=显示
        enabledValue = true,
        disabledValue = false,
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

    local ok = runCommand(command)
    if not ok then
        return false
    end

    -- 读回校验：这个模块曾被死键静默失效坑过，写成功后立刻验证实际值。
    local readOk, output = runCommand(table.concat({
        "defaults read",
        shellQuote(setting.domain),
        shellQuote(setting.key),
    }, " "))

    if not readOk then
        return false
    end

    local expected = value and "1" or "0"
    local actual = trim(output)
    if actual ~= expected then
        logger.w(string.format("校验失败：%s 期望 %s 实际 %s", setting.displayName, expected, actual))
        return false
    end

    return true
end

local function applyPresentationDefaults()
    for _, setting in ipairs(DEFAULT_SETTINGS) do
        writeDefault(setting, setting.enabledValue)
    end
end

local function restorePresentationDefaults()
    for _, setting in ipairs(DEFAULT_SETTINGS) do
        if writeDefault(setting, setting.disabledValue) then
            logger.i(string.format("退出演示模式，恢复%s为 %s", setting.displayName, tostring(setting.disabledValue)))
        end
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
    applyPresentationDefaults()
    active = true
    updateMenubar()
    showStatus("已进入演示模式")
end

local function disablePresentationMode()
    restorePresentationDefaults()

    active = false
    deleteFile(STATE_PATH)
    updateMenubar()
    showStatus("已退出演示模式并显示桌面和小组件")
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
        restorePresentationDefaults()
        active = false
        deleteFile(STATE_PATH)
        updateMenubar()
        showStatus("已强制显示桌面和小组件")
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