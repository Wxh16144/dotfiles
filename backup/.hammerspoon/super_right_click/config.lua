-- super_right_click/config.lua
--
-- 超级右键配置。

return {
    -- 键盘快捷键
    hotkeyMods = {"cmd", "ctrl"},
    hotkeyKey = "1",

    -- 终端应用（"Terminal" 或 "iTerm2"）
    terminalApp = "iTerm2",

    -- 是否记住最近使用的复制操作（动态调整一级菜单）
    rememberLastCopy = true,

    -- 工具候选列表（按分类组织）。启动时自动过滤未安装的。
    -- code = 代码编辑器，git = Git GUI 工具（仅在 git 仓库中显示，打开仓库根）
    toolCandidates = {
        code = {
            {title = "VS Code",              cmd = "/usr/local/bin/code"},
            {title = "VS Code（禁用扩展）",   cmd = "/usr/local/bin/code", args = {"--disable-extensions"}},
            {title = "Zed",                  cmd = "/usr/local/bin/zed"},
            {title = "Xcode",                cmd = "/usr/bin/xed"},
        },
        git = {
            {title = "Fork",                 cmd = "/usr/local/bin/fork"},
            {title = "SourceTree",           cmd = "/usr/local/bin/stree"},
        },
    },
}
