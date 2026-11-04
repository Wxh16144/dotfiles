-- lib/shell.lua
--
-- shell 相关工具：把字符串转成可直接粘贴到终端的字面量。

local M = {}

-- 用单引号包裹，路径内的单引号用 '\'' 断开转义。
-- 单引号内空格、$、`、!、&、" 等字符都不会被 shell 解释。
function M.quote(s)
    if s == nil then return s end
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

return M
