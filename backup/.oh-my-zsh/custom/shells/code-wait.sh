#!/bin/bash

# chmod 755 $ZSH_CUSTOM/shells/code-wait.sh
# see: https://stackoverflow.com/a/65142525

OPTS=""
# 检查是否为临时文件 (例如 git commit message)
# /tmp/*: 标准临时目录
# $TMPDIR*: macOS 特有的临时目录 (通常是 /var/folders/...)
if [[ "$1" == /tmp/* ]] || [[ -n "$TMPDIR" && "$1" == "$TMPDIR"* ]]; then
    # -w: 等待文件关闭 (Wait)，这对 git commit 很重要
    # --disable-extensions: 禁用扩展，加快启动速度并减少干扰
    OPTS="-w --disable-extensions"
fi

CODE=$(which code)

# -a: 将文件添加到最近使用的窗口，而不是打开新窗口
CODE ${OPTS:-} -a "$@"
