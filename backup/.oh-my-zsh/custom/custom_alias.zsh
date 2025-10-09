# !!! rm 像魔鬼一样刺激我的多巴胺, 尽管它能带给我快感, 但我还是要抵制它 !!!
# alias rm="echo Use 'rmm', or the full path i.e. '/bin/rm'"
function rm() {
  # https://iboysoft.com/questions/why-is-there-no-put-back-button-in-mac-trash.html
  echo -e '\033[31mUse "rmm", or the full path i.e. "/bin/rm"\033[0m'
  if ! command -v trash &> /dev/null; then
    echo -e '\033[31mtrash command not found. Please install trash first.\033[0m'
    return
  fi
  trash "$@"
}
alias rmm="trash" # brew install trash

# -------------------------------- #
# Application alias
# -------------------------------- #
# https://stackoverflow.com/a/19663203/11302760
alias st='open -a SourceTree .'
alias f="open_fork"
alias fk="caffeinate -u -t 3600" # prevent mac from sleeping

# -------------------------------- #
# Directory alias
# -------------------------------- #
alias w="cd $WORKSPACE"
alias com="cd $COMPANY"
# alias stu="cd $STUDY"
alias oss="cd $OSS"
alias my="cd $MY"
alias play="cd $PLAY"
alias llm="cd $LLM"
alias con="cd $CONFIG"
alias scr="cd $SCRIPTS"

# https://link.wxhboy.cn/08e37fd
alias jj="j -i"
alias jb="j -b"

# https://link.wxhboy.cn/dd17741
alias me="wxh16144 -h"
alias wxh="wxh16144 -h"

# -------------------------------- #
# Node Package Manager
# dependent on https://github.com/wxh16144/ni or @antfu/ni
# -------------------------------- #
alias i="ni"
alias .i="pnpm install --node-linker=hoisted"

alias io="ni --prefer-offline"
alias nio="ni --prefer-offline"

alias rei="re-install-fe-deps"

# alias s="nr start"
alias s="start_fe_project"

# alias b="nr build"
alias b="compile_fe_peoject"
alias t="nr test"
alias tw="nr test --watch"
alias tu="nr test -u"
alias lint="nr lint"
alias lintf="nr lint --fix"
alias release="npx release-it"
alias nrr="npm_registry_manage" # npm registry manage

# listing packages from workspace (https://github.com/pnpm/pnpm/issues/1519)
alias lsw="pnpm m ls --json --depth=-1 | jq '.[] | .path' | sed 's?'$PWD/'??'"

# -------------------------------- #
# Command Line Tools
# -------------------------------- #
alias o="open ."
alias p="pwd"
alias e="exit"
alias h='history'
alias cpwd="pwd | pbcopy && echo successfully"
alias big='du -s ./* | sort -nr | awk '\''{print $2}'\'' | xargs du -sh'
alias cl='count_lines'
alias project='quick_start_project'

# https://ollama.com/
alias ai="ollama"
alias killai="pgrep -f ollama | xargs kill -9"

# https://github.com/dotenvx/dotenvx
alias envx="dotenvx"

# https://askubuntu.com/a/473770
alias c="clear && printf '\e[3J'"

# where tree
alias tree="/opt/homebrew/bin/tree -I 'node_modules|cache|test_*' -L 3"

# hide a directory or file
alias hide="chflags hidden"
alias show="chflags nohidden"

# https://stackoverflow.com/a/71716482
alias hideicon="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showicon="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# front-end-node_modules
alias lsnm="list_node_modules"
alias rmnm="remove_node_modules"

# nvm install
alias nvmi="nvm_install"

alias del="remove_all_files"
alias dir="create_and_cd"
alias dirt="create_tmp_dir"
alias dirp="create_tmp_play_dir"

# network
alias ip="get_ip"
alias ipl="get_ip_local"
alias ser="quick_server"
alias pser="private_server"
alias port="list_common_ports" # 列举一些常用的端口占用情况
alias portkill="kill_port" # 杀掉指定端口的进程

# zsh
alias zshrc='code --disable-extensions "${ZDOTDIR:-$HOME}"/.zshrc'
alias reload='source "${ZDOTDIR:-$HOME}"/.zshrc'
alias custom="code --disable-extensions $ZSH_CUSTOM"

# -------------------------------- #
# Git shortcut
# -------------------------------- #
alias clone="clone_and_cd"
alias clonet="clone_to_tmp_dir"
alias clonemy="clone_my_project"
alias cloneoss="clone_oss_project"

# clone https://github.com/react-component/xxx.git
alias cloneossrc="clone_oss_org_project react-component"
alias rc="cd $OSS/react-component"

# clone https://github.com/umijs/xxx.git
alias cloneossumijs="clone_oss_org_project umijs"
alias umi="cd $OSS/umijs"

# clonse https://github.com/ant-design/xxx.git
alias cloneossant="clone_oss_org_project ant-design"
alias antd="cd $OSS/ant-design"

# http://github.com/lobehub/xxx.git
alias lobehub="cd $OSS/lobehub"

# 切换到指定分支(默认主分支)拉取更新后，再切回来
alias gbsw="git_branch_pull_switch"

# 列举当前仓库的活跃分支
alias gitav="git_active_branches"

# 快速修复某一条记录(默认上一条)，并进行 rebase squash 操作
alias gfix="git_fixup_commit"

# 归档指定 hash 的代码快照到 archive 目录
alias garc="git_archive_by_hash"

# 使用一个分支备份当前 git 修改
alias gbp="git_create_branch_backup"

# 批量删除分支, 支持 grep 参数，输入 y 确定删除
alias gbdel="git_batch_delete_branch"

# 列举本地常见的分支的 hash
alias gblhash="list_local_branch_hash"

# 解析 url 并添加 git remote
alias gae="git_add_remote"

# 将指定目录推送到远程仓库
alias pudir="push_ignored_directory"

# 覆盖 antd 依赖，仅支持 rc-xxx 依赖
alias oad="override-antd-deps"
