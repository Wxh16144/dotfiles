-- auto_quit_apps/auto_quit_apps.lua
--
-- 锁屏一段时间后自动退出指定应用，休眠时立即退出指定应用。
-- 工作日延迟 20 分钟，周末延迟 10 分钟。

local DEFAULT_WORKDAY_DELAY = 20 * 60
local DEFAULT_WEEKEND_DELAY = 10 * 60
local COMPLETION_NOTIFICATION_TTL = 24 * 60 * 60

local APPS = {
    {
        displayName = "微信",
        names = {"微信", "WeChat"},
        quitMenuTitles = {"退出微信", "Quit WeChat"},
    },
    -- {
    --     displayName = "飞书",
    --     names = {"飞书", "Feishu", "Lark"},
    --     quitMenuTitles = {"退出飞书", "Quit Feishu", "Quit Lark"},
    -- },
    {
        displayName = "钉钉",
        names = {"钉钉", "DingTalk"},
        quitMenuTitles = {"退出钉钉", "Quit DingTalk"},
    },
    {
        displayName = "Telegram",
        names = {"Telegram"},
        quitMenuTitles = {"退出 Telegram", "Quit Telegram"},
    },
    -- {
    --     displayName = "Discord",
    --     names = {"Discord"},
    --     quitMenuTitles = {"退出 Discord", "Quit Discord"},
    -- },
}

hs.application.enableSpotlightForNameSearches(true)

local logger = hs.logger.new("auto_quit_apps", "info")

local enabled = true
local screenWatcher = nil
local closeAppsTimer = nil

local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        logger.e("ERROR: " .. tostring(result))
        return false, result
    end

    return true, result
end

local function isWeekend()
    local wday = tonumber(os.date("%w"))
    return wday == 0 or wday == 6
end

local function getDelay()
    return isWeekend() and DEFAULT_WEEKEND_DELAY or DEFAULT_WORKDAY_DELAY
end

local function getApp(appConfig)
    for _, appName in ipairs(appConfig.names) do
        local app = hs.application.get(appName)
        if app then
            return app
        end
    end

    return nil
end

local function clearTimer()
    if closeAppsTimer then
        closeAppsTimer:stop()
        closeAppsTimer = nil
        logger.i("已清除自动退出定时器")
        return true
    end

    return false
end

local function sendCompletionNotification(appConfig)
    local timeStr = os.date("%Y-%m-%d %H:%M")
    hs.notify.new(nil, {
        title = appConfig.displayName .. "自动退出",
        informativeText = timeStr .. " 已为你自动退出" .. appConfig.displayName,
    }):withdrawAfter(COMPLETION_NOTIFICATION_TTL):send()
end

local function quitApp(appConfig)
    local app = getApp(appConfig)

    if not app then
        logger.i(appConfig.displayName .. "未运行，跳过退出")
        return false
    end

    logger.i("尝试通过应用菜单退出" .. appConfig.displayName)

    for _, appName in ipairs(appConfig.names) do
        for _, quitMenuTitle in ipairs(appConfig.quitMenuTitles or {}) do
            local ok, selected = safeCall(function()
                return app:selectMenuItem({appName, quitMenuTitle})
            end)

            if ok and selected then
                logger.i("已发送菜单退出指令: " .. appConfig.displayName)
                return true
            end
        end
    end

    logger.w(appConfig.displayName .. "菜单退出不可用，改用 hs.application:kill() 优雅终止")
    local ok = safeCall(function()
        app:kill()
    end)

    return ok
end

local function quitConfiguredApps(reason)
    local quitCount = 0

    for _, appConfig in ipairs(APPS) do
        local ok, didQuit = safeCall(function()
            return quitApp(appConfig)
        end)

        if ok and didQuit then
            quitCount = quitCount + 1
            if reason == "timer" then
                sendCompletionNotification(appConfig)
            end
        end
    end

    return quitCount
end

local function getRunningConfigs()
    local runningConfigs = {}

    for _, appConfig in ipairs(APPS) do
        if getApp(appConfig) then
            table.insert(runningConfigs, appConfig)
        else
            logger.i("锁屏，但" .. appConfig.displayName .. "未运行，跳过创建定时器")
        end
    end

    return runningConfigs
end

local function joinDisplayNames(appConfigs)
    local names = {}

    for _, appConfig in ipairs(appConfigs) do
        table.insert(names, appConfig.displayName)
    end

    return table.concat(names, "、")
end

local function onScreenLocked()
    if not enabled then
        logger.i("应用自动退出已禁用，跳过锁屏逻辑")
        return
    end

    local runningConfigs = getRunningConfigs()
    if #runningConfigs == 0 then
        logger.i("锁屏，但没有配置应用正在运行，不创建定时器")
        return
    end

    clearTimer()

    local delay = getDelay()
    local minutes = math.floor(delay / 60)

    logger.i(string.format("锁屏检测，%s 将在 %d 分钟后退出", joinDisplayNames(runningConfigs), minutes))

    closeAppsTimer = hs.timer.doAfter(delay, function()
        safeCall(function()
            logger.i("锁屏定时器触发，退出配置应用")
            closeAppsTimer = nil

            for _, appConfig in ipairs(runningConfigs) do
                if quitApp(appConfig) then
                    sendCompletionNotification(appConfig)
                end
            end
        end)
    end)

    hs.notify.show("应用自动退出", "", string.format("%s 将在 %d 分钟后自动退出", joinDisplayNames(runningConfigs), minutes))
end

local function onScreenUnlocked()
    local cleared = clearTimer()

    if cleared then
        logger.i("已解锁，取消自动退出任务")
        hs.alert.show("已解锁，取消自动退出任务", 3)
    else
        logger.i("已解锁，无待执行任务")
    end
end

local function onSystemSleep()
    if not enabled then
        logger.i("应用自动退出已禁用，跳过休眠逻辑")
        return
    end

    clearTimer()

    logger.i("系统即将休眠，立即退出配置应用")
    quitConfiguredApps("sleep")
end

local function onSystemWake()
    logger.i("系统唤醒，不执行补偿退出")
end

local function startWatcher()
    if screenWatcher then
        screenWatcher:stop()
        screenWatcher = nil
        logger.i("停止旧监听")
    end

    screenWatcher = hs.caffeinate.watcher.new(function(event)
        safeCall(function()
            if event == hs.caffeinate.watcher.screensDidLock then
                onScreenLocked()
            elseif event == hs.caffeinate.watcher.screensDidUnlock then
                onScreenUnlocked()
            elseif event == hs.caffeinate.watcher.systemWillSleep then
                onSystemSleep()
            elseif event == hs.caffeinate.watcher.systemDidWake then
                onSystemWake()
            end
        end)
    end)

    screenWatcher:start()
    logger.i("监听已启动")
end

startWatcher()

return {
    enable = function()
        enabled = true
        logger.i("应用自动退出已启用")
    end,

    disable = function()
        enabled = false
        clearTimer()
        logger.i("应用自动退出已禁用")
    end,

    isEnabled = function()
        return enabled
    end,

    quitNow = function()
        safeCall(function()
            quitConfiguredApps("manual")
        end)
    end,
}