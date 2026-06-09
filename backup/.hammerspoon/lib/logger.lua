-- lib/logger.lua
--
-- 模块 logger：默认只输出到独立日志文件，避免 Hammerspoon Console 被模块细节刷屏。

local fs = hs.fs
local runtimePaths = require "lib.runtime_paths"
local logDir = runtimePaths.logDir()
local maxLogSize = 1024 * 1024

local LEVELS = {
    verbose = 1,
    debug = 2,
    info = 3,
    warning = 4,
    warn = 4,
    error = 5,
    nothing = 6,
}

local M = {}
local unpackArgs = table.unpack or unpack

local function ensureLogDir()
    if not fs.attributes(logDir) then
        fs.mkdir(logDir)
    end
end

local function normalizeLevel(level)
    level = tostring(level or "debug"):lower()
    if LEVELS[level] then
        return level
    end

    return "debug"
end

local function shouldWrite(currentLevel, messageLevel)
    return LEVELS[messageLevel] >= LEVELS[currentLevel]
end

local function stringifyArgs(...)
    local count = select("#", ...)
    if count == 0 then
        return ""
    end

    if count == 1 then
        return tostring(select(1, ...))
    end

    local args = {...}
    if type(args[1]) == "string" then
        local ok, formatted = pcall(string.format, unpackArgs(args))
        if ok then
            return formatted
        end
    end

    for index, value in ipairs(args) do
        args[index] = tostring(value)
    end

    return table.concat(args, " ")
end

local function rotateIfNeeded(path)
    local attributes = fs.attributes(path)
    if not attributes or not attributes.size or attributes.size < maxLogSize then
        return
    end

    os.remove(path .. ".1")
    os.rename(path, path .. ".1")
end

local function writeFile(path, level, message)
    ensureLogDir()
    rotateIfNeeded(path)

    local file = io.open(path, "a")
    if not file then
        return
    end

    local line = string.format("[%s] [%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), level, message)
    file:write(line)
    file:close()
end

local function setConsoleLevel(consoleLog, level)
    if consoleLog and consoleLog.setLogLevel then
        local ok = pcall(consoleLog.setLogLevel, level)
        if not ok then
            pcall(consoleLog.setLogLevel, consoleLog, level)
        end
    end
end

local function writeConsole(consoleLog, methodName, message)
    if not consoleLog or not consoleLog[methodName] then
        return
    end

    local ok = pcall(consoleLog[methodName], message)
    if not ok then
        pcall(consoleLog[methodName], consoleLog, message)
    end
end

function M.logDir()
    ensureLogDir()
    return logDir
end

function M.new(moduleName, level, options)
    ensureLogDir()
    options = options or {}

    local currentLevel = normalizeLevel(level)
    local consoleLog = options.console and hs.logger.new(moduleName, currentLevel) or nil
    local filePath = runtimePaths.logFile(moduleName, moduleName .. ".log")

    local function write(consoleMethodName, fileLevel, messageLevel, ...)
        local message = stringifyArgs(...)

        writeConsole(consoleLog, consoleMethodName, message)

        if shouldWrite(currentLevel, messageLevel) then
            writeFile(filePath, fileLevel, message)
        end
    end

    return {
        v = function(...)
            write("v", "VERBOSE", "verbose", ...)
        end,

        d = function(...)
            write("d", "DEBUG", "debug", ...)
        end,

        i = function(...)
            write("i", "INFO", "info", ...)
        end,

        w = function(...)
            write("w", "WARN", "warning", ...)
        end,

        e = function(...)
            write("e", "ERROR", "error", ...)
        end,

        setLogLevel = function(nextLevel)
            currentLevel = normalizeLevel(nextLevel)
            setConsoleLevel(consoleLog, currentLevel)
        end,

        filePath = function()
            return filePath
        end,
    }
end

return M