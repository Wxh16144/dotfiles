local runtimePaths = require "lib.runtime_paths"

require("auto_quit_apps.auto_quit_apps").start()
require("presentation_mode.presentation_mode").start()

local initLogger = hs.logger.new("init", "info")
initLogger.i("Hammerspoon 配置已加载")
initLogger.i("runtime data: " .. runtimePaths.dataDir())
initLogger.i("runtime cache: " .. runtimePaths.cacheDir())
initLogger.i("runtime logs: " .. runtimePaths.logDir())