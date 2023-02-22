# https://askubuntu.com/a/473770
alias c="clear && printf '\e[3J'"

# https://stackoverflow.com/a/19663203/11302760
alias st='open -a SourceTree .'

alias p="pwd"
alias e="exit"
alias cpwd="pwd | pbcopy && echo successfully"

export WORKSPACE="$HOME/Code"
alias w="cd $WORKSPACE"

export COMPANY=$WORKSPACE/CompanyProject
alias com="cd $COMPANY"

export STUDY=$WORKSPACE/StudyProject
alias stu="cd $STUDY"
alias oss="cd $STUDY"

export MY=$WORKSPACE/SelfProject
alias my="cd $MY"

export PLAY=$WORKSPACE/Playground
alias play="cd $PLAY"

# 显示/隐藏 隐藏的文件
alias show="sh $ZSH_CUSTOM/custom_shell/show.sh"
alias hide="sh $ZSH_CUSTOM/custom_shell/hide.sh"

# -------------------------------- #
# Node Package Manager
# -------------------------------- #
# https://github.com/antfu/ni

alias i="ni"

# alias s="nr start"
function s() {
  function has_script() {
    [[ $(npm run | grep "^  $1$" | wc -l) -eq 1 ]]
  }

  function run_script() {
    echo "\033[32mCurrent project start method: \033[31;1m$*\033[0m"
    # execute the input command
    eval $*
  }

  if has_script start; then
    run_script $(nr start "?")
  elif has_script dev; then
    run_script $(nr dev "?")
  else
    echo "No dev or start script found."
  fi
}

alias b="nr build"
alias t="nr test"
alias lint="nr lint"
alias lintf="nr lint --fix"

# -------------------------------- #
# Package registry Manage
# -------------------------------- #

function nrr() {
  # na from https://github.com/antfu/ni
  # 预设的 registry
  declare -A registrys
  registrys=(
    [npm]="https://registry.npmjs.org/"
    [yarn]="https://registry.yarnpkg.com/"
    [tencent]="https://mirrors.cloud.tencent.com/npm/"
    [cnpm]="https://r.cnpmjs.org/"
    [taobao]="https://registry.npmmirror.com/"
    [npmMirror]="https://skimdb.npmjs.com/registry/"
    # [company]="https://packages.aliyun.com/616ff38165b9775dd591fcc9/npm/npm-registry/"
    [self]="http://nas.wxhboy.cn:98/"
    [selfIp]="http://192.168.31.10:98/"
  )

  set_registry(){
    # 经常遇到安装依赖问题，索性就把所有的 registry 都设置一下
    npm config set registry $1
    yarn config set registry $1
    echo "Set registry to $1"
  }

  # 如果没有参数, 则表示查看当前 registry，并且询问是否要重置为默认 registry [npm]
  if [ $# -eq 0 ]; then
    echo "Current registry: $(na config get registry)"

    echo -n -e "Reset to default registry[npm]? [y/n] "
    read agreeReset
    if [ $agreeReset = "y" ]; then
      set_registry ${registrys[npm]}
      echo "Reset to default registry: ${registrys[npm]}"
    fi
    return
  fi

  # 判断输入的 registry 是否存在
  if [ -z ${registrys[$1]} ]; then
    echo "Registry not found: $1"
    echo "Available registrys:"
    for key in ${(@k)registrys}; do
      echo "  $key: ${registrys[$key]}"
    done
    return
  fi

  set_registry ${registrys[$1]}
  # echo "Set registry to: ${registrys[$1]}"
}

# -------------------------------- #
# Command Line Tools
# -------------------------------- #
function treem(){
  tree -I 'node_modules|cache|test_*' -L 3 $@
}

# 列出当前目录下的所有 node_modules
function lsnm(){
  find . -name "node_modules" -type d -prune
}

# 删除当前目录下的所有 node_modules
function rmnm(){
  local nm=$(lsnm)
  if [[ $1 == "-a" ]]; then
    echo $nm | xargs -n 1 rm -rf
    echo "All node_modules have been removed."
  else
    echo $nm | xargs -n 1 -p rm -rf
  fi
}

# 删除当前目录所有文件(危险操作)
function rmc(){
  local currentDir=$(pwd)

  echo -n -e "Are you sure to remove all files in \033[31;1m$currentDir\033[0m? [y/n] "
  read agreeRemove
  if [ $agreeRemove = "y" ]; then
    rm -rf $currentDir
    echo "All files have been removed."
    cd ..
  fi
}

# -------------------------------- #
# Directories
#
# `~/Code/SelfProject` for my projects
# `~/Code/StudyProject` for OSS projects
# -------------------------------- #

# hide a directory or file
function hidedir(){
  chflags hidden $1
}

# unhide a directory or file
function unhidedir(){
  chflags nohidden $1
}

function dir() {
  mkdir -p $1 && cd $1
}

function clone() {
  if [[ -z $2 ]] then
    git clone --recurse-submodules "$@" && cd "$(basename "$1" .git)"
  else
    git clone --recurse-submodules "$@" && cd "$2"
  fi
}

function clonemy() {
  my && clone "$@" && code --disable-extensions .
}

function cloneoss() {
  oss # cd directory
  clone "$@"

  local repo=$1

  if [[ $repo =~ "git@github.com" ]]; then
    local repoName=$(basename "$repo" .git)
    # setting upstream
    git remote add upstream $repo
    git remote set-url origin "git@github.com:Wxh16144/$repoName.git"

    # Get the unique branch name after cloning
    local branchName=$(git branch -a | grep remotes/origin/HEAD | sed 's/.*\///')
    if [[ -z $branchName ]]; then
      branchName="master"
    fi

    git fetch upstream $branchName

    # track the upstream branch
    git branch --set-upstream-to=upstream/$branchName $branchName
  fi

  # wait: https://link.wxhboy.cn/9QEF # 克隆后添加书签到 sourcetree # 暂时估计实现不了

  # https://stackoverflow.com/a/19663203/11302760 # 打开 sourcetree 会提示你是否添加书签
  open -a "SourceTree" .
  
  # code --disable-extensions . # 打开 vscode, 我感觉自己不需要这个了
}

# clone oss project https://github.com/react-component/{repoName}
function cloneossrc() {
  local repo=$1
  local repoName=$(basename "$repo" .git)
  cloneoss "$repo" "react-component/$repoName"
}

# -------------------------------- #
# Git shortcut
# -------------------------------- #

# 记录当前分支，切换到指定分支(默认 master)拉取更新后，再切换回来
function gbsw() {
  local defaultTarget="master"
  
  if [[ -n $(git status --porcelain) ]] then
    echo "current workspace is dirty, please save first"
    git status -sb
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD)
  local target=${1:-$defaultTarget}

  git checkout $target
  git pull
  git checkout $branch

  echo -n -e "Do you want to rebase? [y/N]"
  read isRebase
  if [[ $isRebase == "y" ]] then
    git rebase $target
  fi
}

# 快速修复某一条记录(默认上一条)，并进行 rebase squash 操作
function gfix() {
  if [[ -z $(git diff --cached --name-only) ]] then
    echo "no staged files"
    git status -sb
    return 1
  fi

  local hash=$1
  if [[ -z $hash ]] then
    hash=$(git log -1 --pretty=%H)
  fi

  git commit --fixup $hash
  
  # --autosquash 模式不支持非交互式 reabse, 需要通过环境变量控制
  # https://stackoverflow.com/questions/29094595/git-interactive-rebase-without-opening-the-editor#answer-29094904
  GIT_SEQUENCE_EDITOR=: git rebase -i $hash^ --autosquash
}

# 使用一个分支备份当前 git 修改
function gbp() {
  local new_branch="$(whoami)/$(date +%Y/%m/%d-%H_%M_%S)"

  # 工作区是干净的
  if [[ -z $(git status --porcelain) ]] then
    git branch $new_branch
    echo "The current workspace is clean, and a new branch:${new_branch} is created"
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD)
  local hash=$(git rev-parse --short HEAD)

  local staged=$(git diff --cached --name-only)
  # local unstaged=$(git diff --name-only)

  git add -A
  git commit --no-verify --no-gpg-sign -m "backup: WIP ${branch}[${hash}] (--skip-ci)"
  
  git checkout -b $new_branch

  git checkout $branch
  git reset --mixed HEAD^
  
  if [[ -n $staged ]] then
    git add $staged
  fi
}

# 批量删除分支, 支持 grep 参数，输入 y 确定删除
function gbdel() {
  local branches=$(git branch --all | awk '{print $1}')
  local ignore_branches=$(echo "$branches" | grep -v -E '^(master|dev|test)$|^dev-|^remotes|\*')
  echo "$ignore_branches" | grep ${1-.} | xargs -n 1 -p git branch -D
}

# 解析 url 并添加 git remote
function gae(){
  local url=$1
  local userName=$(echo $url | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')

  if [[ -z $userName ]] then
    echo "invalid url"
    return 1
  fi

  git remote add $userName $url

  echo -e "remote \033[32;1m$userName\033[0m added"

  echo -n -e "Do you want to fetch remote? [y/N]"
  read isFetch
  if [[ $isFetch == "y" ]] then
    git fetch $userName
  fi
}
