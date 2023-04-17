# -------------------------------- #
# Application alias
# -------------------------------- #
# https://stackoverflow.com/a/19663203/11302760
# alias st='open -a SourceTree .'
alias f="open_fork"

# -------------------------------- #
# Directory alias
# -------------------------------- #
alias w="cd $WORKSPACE"
alias com="cd $COMPANY"
# alias stu="cd $STUDY"
alias oss="cd $OSS"
alias my="cd $MY"
alias play="cd $PLAY"

# -------------------------------- #
# Node Package Manager
# dependent on https://github.com/wxh16144/ni
# -------------------------------- #
alias i="ni"

# alias s="nr start"
alias s="start_fe_project"

alias b="nr build"
alias t="nr test"
alias lint="nr lint"
alias lintf="nr lint --fix"
alias nrr="npm_registry_manage" # npm registry manage

# -------------------------------- #
# Command Line Tools
# -------------------------------- #
alias p="pwd"
alias e="exit"
alias h='history'
alias cpwd="pwd | pbcopy && echo successfully"
alias big='du -s ./* | sort -nr | awk '\''{print $2}'\'' | xargs du -sh'

# https://askubuntu.com/a/473770
alias c="clear && printf '\e[3J'"

alias treem="tree -I 'node_modules|cache|test_*' -L 3"

# hide a directory or file
alias hidedir="chflags hidden"

# unhide a directory or file
alias unhidedir="chflags nohidden"

# front-end-node_modules
alias lsnm="list_node_modules"
alias rmnm="remove_node_modules"

# nvm install
alias nvmi="nvm_install"

alias rmc="remove_all_files"
alias dir="create_and_cd"

# network
alias ip="get_ip"
alias ipl="get_ip_local"
alias ser="start_server"


# zsh
alias zshrc='code --disable-extensions "${ZDOTDIR:-$HOME}"/.zshrc'
alias reload='source "${ZDOTDIR:-$HOME}"/.zshrc'
alias custom="code --disable-extensions $ZSH_CUSTOM"

# -------------------------------- #
# Git shortcut
# -------------------------------- #
alias clone="clone_and_cd"
alias clonemy="clone_my_project"
alias cloneoss="clone_oss_project"

# clone https://github.com/react-component/xxx.git
alias cloneossrc="clone_oss_org_project react-component"
# clone https://github.com/umijs/xxx.git
alias cloneossumijs="clone_oss_org_project umijs"

# 切换到指定分支(默认主分支)拉取更新后，再切回来
alias gbsw="git_branch_pull_switch"

# 快速修复某一条记录(默认上一条)，并进行 rebase squash 操作
alias gfix="git_fixup_commit"

# 使用一个分支备份当前 git 修改
alias gbp="git_create_branch_backup"

# 批量删除分支, 支持 grep 参数，输入 y 确定删除
alias gbdel="git_batch_delete_branch"

# 解析 url 并添加 git remote
alias gae="git_add_remote"

# 将指定目录推送到远程仓库
alias pudir="push_ignored_directory"
