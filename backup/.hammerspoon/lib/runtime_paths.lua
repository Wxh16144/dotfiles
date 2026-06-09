-- lib/runtime_paths.lua
--
-- 自定义 Hammerspoon 配置的运行时文件路径。配置源码留在 ~/.hammerspoon，状态、日志等放到专属用户目录。

local fs = hs.fs
local home = os.getenv("HOME")

local function slugify(value)
    local slug = tostring(value or "user")
        :lower()
        :gsub("[^%w._-]+", "-")
        :gsub("^-+", "")
        :gsub("-+$", "")

    return slug ~= "" and slug or "user"
end

local runtimeOwner = os.getenv("HAMMERSPOON_RUNTIME_NAMESPACE")
    or os.getenv("USER")
    or os.getenv("LOGNAME")
    or "user"

local namespace = slugify(runtimeOwner) .. "-hammerspoon"
local roots = {
    data = home .. "/Library/Application Support/" .. namespace,
    cache = home .. "/Library/Caches/" .. namespace,
    log = home .. "/Library/Logs/" .. namespace,
}

local M = {}

local function join(...)
    local parts = {...}
    local path = tostring(parts[1] or "")

    for index = 2, #parts do
        local part = tostring(parts[index] or "")
        if part ~= "" then
            path = path:gsub("/+$", "") .. "/" .. part:gsub("^/+", "")
        end
    end

    return path
end

local function ensureDir(path)
    if fs.attributes(path) then
        return path
    end

    local parent = path:match("^(.*)/[^/]+$")
    if parent and parent ~= path then
        ensureDir(parent)
    end

    fs.mkdir(path)
    return path
end

function M.dataDir(...)
    return ensureDir(join(roots.data, ...))
end

function M.cacheDir(...)
    return ensureDir(join(roots.cache, ...))
end

function M.logDir(...)
    return ensureDir(join(roots.log, ...))
end

function M.stateFile(moduleName, fileName)
    return join(M.dataDir("state", moduleName), fileName)
end

function M.logFile(moduleName, fileName)
    return join(M.logDir(moduleName), fileName)
end

return M