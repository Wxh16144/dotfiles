-- auto_theme/auto_theme.lua
--
-- 按时间轴自动切换 macOS 浅色/深色外观：用 AppleScript 直接改 appearance，
-- 不重启 Finder/Dock 等进程。定时器在睡眠期间会暂停，所以唤醒后会重新校准。

-- 时间轴：只在切换点触发，中途不轮询。早于首条的时刻沿用最后一条（跨天回绕）。
-- time 支持 "9:00" 与 "09:00"；appearance 只接受 "light" / "dark"。
local SCHEDULE = {
    {time = "00:01", appearance = "dark"},
    {time = "09:00", appearance = "light"},
    {time = "11:30", appearance = "dark"},
    {time = "13:30", appearance = "light"},
    {time = "18:00", appearance = "dark"},
    {time = "22:00", appearance = "light"},
    {time = "23:59", appearance = "dark"},
}

-- 关闭系统「自动（日出日落）」外观，避免系统与时间轴互相覆盖。
local DISABLE_AUTO_APPEARANCE = true

-- 实际发生切换时发系统通知的时机。start/enable 是手动触发（重载、开开关），不发通知避免刷屏；
-- 想彻底关掉通知，把这张表清空即可。
local NOTIFY_REASONS = {
    boundary = true,
    wake = true,
}

local SECONDS_PER_DAY = 24 * 60 * 60

local logger = require("lib.logger").new("auto_theme", "info")

local enabled = true
local schedule = nil
local nextTimer = nil
local wakeWatcher = nil
local permissionWarned = false

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

local function formatTime(timeSec)
    local seconds = math.floor(tonumber(timeSec) or 0)
    return string.format("%02d:%02d", math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60)
end

-- ============================================================
-- 时间轴解析
-- ============================================================

local function parseTime(value)
    local hour, minute = trim(value):match("^(%d%d?):(%d%d)$")
    hour = tonumber(hour)
    minute = tonumber(minute)

    if not hour or not minute or hour > 23 or minute > 59 then
        return nil
    end

    return hour * 3600 + minute * 60
end

local function normalizeAppearance(value)
    local appearance = trim(value):lower()
    if appearance == "light" or appearance == "dark" then
        return appearance
    end

    return nil
end

local function buildSchedule()
    local parsed = {}

    for index, entry in ipairs(SCHEDULE) do
        local timeSec = parseTime(entry.time)
        local appearance = normalizeAppearance(entry.appearance)

        if not timeSec then
            logger.w(string.format("时间轴第 %d 项时间无效（%s），已跳过", index, tostring(entry.time)))
        elseif not appearance then
            logger.w(string.format("时间轴第 %d 项外观无效（%s），已跳过", index, tostring(entry.appearance)))
        else
            table.insert(parsed, {
                timeSec = timeSec,
                appearance = appearance,
            })
        end
    end

    if #parsed == 0 then
        return nil
    end

    table.sort(parsed, function(a, b)
        return a.timeSec < b.timeSec
    end)

    local labels = {}
    for _, entry in ipairs(parsed) do
        table.insert(labels, formatTime(entry.timeSec) .. "=" .. entry.appearance)
    end
    logger.i("时间轴: " .. table.concat(labels, " "))

    return parsed
end

-- 当前时刻应处于的外观：取 timeSec <= nowSec 的最后一条；早于首条则回绕到末条。
local function expectedAppearanceAt(nowSec)
    if not schedule then
        return nil
    end

    local expected = schedule[#schedule].appearance
    for _, entry in ipairs(schedule) do
        if entry.timeSec <= nowSec then
            expected = entry.appearance
        else
            break
        end
    end

    return expected
end

-- 距下一个切换点的秒数：取 timeSec > nowSec 的第一条；没有则回绕到次日首条。
local function secondsUntilNextChange(nowSec)
    if not schedule then
        return nil
    end

    for _, entry in ipairs(schedule) do
        if entry.timeSec > nowSec then
            return entry.timeSec - nowSec
        end
    end

    return SECONDS_PER_DAY - nowSec + schedule[1].timeSec
end

-- ============================================================
-- 外观读写
-- ============================================================

local function runApplescript(source)
    local ok, result, descriptor = hs.osascript.applescript(source)
    if ok then
        return true, result
    end

    logger.e("AppleScript 执行失败: " .. tostring(descriptor or result))

    -- 报错 -1743 表示没有自动化权限；只提示一次，避免反复弹窗。
    if not permissionWarned and tostring(descriptor or ""):find("-1743", 1, true) then
        permissionWarned = true
        hs.alert.show("自动主题需要自动化权限：系统设置 → 隐私与安全性 → 自动化，勾选 Hammerspoon 下的 System Events", 6)
    end

    return false, result
end

local function getDarkMode()
    local ok, result = runApplescript([[
tell application "System Events" to tell appearance preferences to get dark mode
]])

    if not ok or type(result) ~= "boolean" then
        return nil
    end

    return result
end

local function setDarkMode(dark)
    local ok = runApplescript(string.format([[
tell application "System Events" to tell appearance preferences to set dark mode to %s
]], dark and "true" or "false"))

    return ok
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

    return ok
end

local function disableAutoAppearance()
    if not DISABLE_AUTO_APPEARANCE then
        return
    end

    logger.i("关闭系统自动外观（日出日落）")
    runCommand("defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false")
end

local function notifySwitch(reason, appearance, nowSec)
    if not NOTIFY_REASONS[reason] then
        return
    end

    -- 通知只是辅助提示，失败不能影响主题切换本身。
    safeCall(function()
        local title = appearance == "dark" and "🌙 已切换为深色" or "☀️ 已切换为浅色"
        -- hs.notify.show 默认 5 秒后自动收起，且不指定 soundName 时静音。
        hs.notify.show(title, "", formatTime(nowSec) .. " 按时间轴自动切换")
    end)
end

local function applyCurrent(reason)
    local nowSec = hs.timer.localTime()
    local expected = expectedAppearanceAt(nowSec)
    if not expected then
        return
    end

    local current = getDarkMode()
    if current == nil then
        logger.w(string.format("无法读取当前外观（%s），跳过本次切换", reason))
        return
    end

    local expectedDark = expected == "dark"
    if current == expectedDark then
        logger.d(string.format("%s：%s 已是 %s，无需切换", reason, formatTime(nowSec), expected))
        return
    end

    if setDarkMode(expectedDark) then
        logger.i(string.format("%s：%s 按时间轴切换为 %s", reason, formatTime(nowSec), expected))
        notifySwitch(reason, expected, nowSec)
    end
end

-- ============================================================
-- 调度
-- ============================================================

local function clearNextTimer()
    if nextTimer then
        nextTimer:stop()
        nextTimer = nil
    end
end

local onBoundary

local function scheduleNext()
    clearNextTimer()

    if not schedule or not enabled then
        return
    end

    local nowSec = hs.timer.localTime()
    local delay = secondsUntilNextChange(nowSec)

    -- 定时器最多提前 1 秒触发；提前时下一次求值会重新排到真正的切换点。
    nextTimer = hs.timer.doAfter(math.max(delay, 1), onBoundary)
    logger.d(string.format("下次切换 %s（%d 秒后）", formatTime(nowSec + delay), math.floor(delay)))
end

onBoundary = function()
    nextTimer = nil

    safeCall(function()
        applyCurrent("boundary")
        scheduleNext()
    end)
end

local function stopWatcher()
    if wakeWatcher then
        wakeWatcher:stop()
        wakeWatcher = nil
        logger.i("唤醒监听已停止")
    end
end

local function startWatcher()
    stopWatcher()

    wakeWatcher = hs.caffeinate.watcher.new(function(event)
        if event ~= hs.caffeinate.watcher.systemDidWake then
            return
        end

        safeCall(function()
            -- 睡眠期间定时器暂停，唤醒后补一次求值，修正跨过的切换点。
            logger.i("系统唤醒，重新校准外观")
            applyCurrent("wake")
            scheduleNext()
        end)
    end)

    wakeWatcher:start()
    logger.i("唤醒监听已启动")
end

return {
    start = function()
        schedule = buildSchedule()
        if not schedule then
            logger.e("时间轴为空或全部无效，自动主题未启动")
            return
        end

        disableAutoAppearance()
        applyCurrent("start")
        scheduleNext()
        startWatcher()
        logger.i("自动主题已加载")
    end,

    stop = function()
        clearNextTimer()
        stopWatcher()
        logger.i("自动主题已停止")
    end,

    enable = function()
        enabled = true
        applyCurrent("enable")
        scheduleNext()
        logger.i("自动主题已启用")
    end,

    disable = function()
        enabled = false
        clearNextTimer()
        logger.i("自动主题已禁用")
    end,

    isEnabled = function()
        return enabled
    end,

    nextChangeIn = function()
        if not nextTimer then
            return nil
        end

        return nextTimer:nextTrigger()
    end,
}
