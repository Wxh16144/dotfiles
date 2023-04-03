# 在当前目录中打开 fork 应用程序
# https://git-fork.com/
function open_fork() {
  if [[ -d .git ]]; then
    open -a Fork .
  else
    echo "Not a git repository."
  fi
}

# 判断 package.json 中是否存在指定的 script
function has_script() {
  [[ $(npm run | grep "^  $1$" | wc -l) -eq 1 ]]
}

# 判断并启动前端工程化项目
# 依赖
#   - nr: https://github.com/wxh16144/ni
function start_fe_project() {

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

# 管理 npm registry
# useage: npm_registry_manage [registry]
# 依赖
#   - na: https://github.com/wxh16144/ni
#   - COMPANY_NPM_REGISTRY 环境变量
function npm_registry_manage() {
  local input_registry=$1
  # 预设的 registry
  declare -A registrys
  registrys=(
    [npm]="https://registry.npmjs.org/"
    [yarn]="https://registry.yarnpkg.com/"
    [tencent]="https://mirrors.cloud.tencent.com/npm/"
    [cnpm]="https://r.cnpmjs.org/"
    [taobao]="https://registry.npmmirror.com/"
    [npmMirror]="https://skimdb.npmjs.com/registry/"
    [company]=$COMPANY_NPM_REGISTRY
    [self]="http://nas.wxhboy.cn:98/"
    [selfIp]="http://192.168.31.10:98/"
  )

  set_registry(){
    # 经常遇到安装依赖问题，索性就把所有的 registry 都设置一下
    npm config set registry $input_registry
    yarn config set registry $input_registry
    echo "Set registry to $input_registry"
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
  if [ -z ${registrys[$input_registry]} ]; then
    if [[ $input_registry != "h" && $input_registry != "help" && $input_registry != "ls" ]]; then
      # echo "Registry $input_registry not found."
      echo "\033[31;1mRegistry $input_registry not found.\033[0m"
    fi

    echo "\033[32;1mAvailable registrys:"

    for key in ${(@k)registrys}; do
      # echo "  $key: ${registrys[$key]}"
      echo "\033[31;1m$key\033[0m: \033[32;1m${registrys[$key]}\033[0m"
    done
    return
  fi

  set_registry ${registrys[$input_registry]}
  # echo "Set registry to: ${registrys[$input_registry]}"
}

# 列出当前目录下的所有 node_modules
function list_node_modules() {
  find . -name "node_modules" -type d -prune
}

# 删除当前目录下的所有 node_modules
# useage: remove_node_modules [-a]
# 输入 y 确认删除, 默认不删除, 可以使用 -a 不需要确认并删除所有
function remove_node_modules() {
  local nm=$(list_node_modules)
  if [[ $1 == "-a" ]]; then
    echo $nm | xargs -n 1 rm -rf
    echo "All node_modules have been removed."
  else
    echo $nm | xargs -n 1 -p rm -rf
  fi
}

# 删除当前目录所有文件(危险操作)
function remove_all_files() {
  local currentDir=$(pwd)

  echo -n -e "Are you sure to remove all files in \033[31;1m$currentDir\033[0m? [y/n] "
  read agreeRemove
  if [ $agreeRemove = "y" ]; then
    rm -rf $currentDir
    echo "All files have been removed."
    # 判断上一条记录地址是否存在，如果存在则进入，否则进入 ../
    if [[ -d $OLDPWD ]]; then
      cd $OLDPWD
    else
      cd ..
    fi
  fi
}

# 创建目录并进入, 如果目录已存在则直接进入
# useage: create_and_cd [dir/path]
function create_and_cd() {
  local dir=$1
  if [[ -d $dir ]]; then
    cd $dir
    return
  fi
  mkdir -p $dir && cd $dir
}

# clonse git 仓库并进入
# useage: clone_and_cd [repo] [dir/path]
function clone_and_cd() {
  if [[ -z $2 ]] then
    git clone --recurse-submodules "$@" && cd "$(basename "$1" .git)"
  else
    git clone --recurse-submodules "$@" && cd "$2"
  fi
}

# 克隆自己的项目
# 依赖
#   - MY 环境变量(自己的项目目录)
function clone_my_project() {
  local repo=$1
  local project_path=$MY/$(basename $repo .git)

  if [[ -n $2 ]]; then
    project_path=$MY/$2
  fi

  clone_and_cd $repo $project_path
}

# 克隆开源项目
# 依赖
#   - OSS 环境变量(开源项目目录)
#   - GITHUB_NAME 环境变量(自己的 github 用户名)
function clone_oss_project() {
  local repo=$1
  local project_path=$OSS/$(basename $repo .git)

  if [[ -n $2 ]]; then
    project_path=$OSS/$2
  fi

  clone_and_cd $repo $project_path

  # 添默认添加自己为 origin
  if [[ $repo =~ "git@github.com" ]]; then
    local repoName=$(basename "$repo" .git)
    # setting upstream
    git remote add upstream $repo
    git remote set-url origin "git@github.com:$GITHUB_NAME/$repoName.git"

    # Get the unique branch name after cloning
    local branchName=$(git branch -a | grep remotes/origin/HEAD | sed 's/.*\///')
    if [[ -z $branchName ]]; then
      branchName="master"
    fi

    git fetch upstream $branchName

    # track the upstream branch
    git branch --set-upstream-to=upstream/$branchName $branchName
  fi

  # 打开 Fork
  open_fork

  # code --disable-extensions . # 打开 vscode, 我感觉自己不需要这个了
}

# 克隆某个常用的开源组织的项目
function clone_oss_org_project() {
  local org=$1
  local repo=$2
  local repoName=$(basename "$repo" .git)

  clone_oss_project $repo $org/$repoName
}

# 获取当前仓库的主分支，如果没有则默认为 init.defaultBranch, 如果没有则默认为 master
function get_main_branch() {
  local mainBranch=$(git branch -a | grep remotes/origin/HEAD | sed 's/.*\///')

  if [[ -z $mainBranch ]]; then
    mainBranch=$(git config --get init.defaultBranch)
  fi

  if [[ -z $mainBranch ]]; then
    mainBranch="master"
  fi

  echo $mainBranch
}

# 记录当前分支，切换到指定分支(默认主分支)拉取更新后，再切换回来
function git_branch_pull_switch() {
  local defaultTarget=$(get_main_branch)

  if [[ -n $(git status --porcelain) ]]; then
    echo "current workspace is dirty, please save first"
    git status -sb
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD)
  local target=${1:-$defaultTarget}

  # 判断是否存在目标分支
  if [[ -z $(git branch -a | grep $target) ]]; then
    echo "target branch not found: $target"
    return 1
  fi

  git checkout $target
  git pull
  git checkout $branch

  echo -n -e "Do you want to rebase? [y/N]"
  read isRebase
  if [[ $isRebase == "y" ]]; then
    git rebase $target
  fi
}

# 快速修复某一条记录(默认上一条)，并进行 rebase squash 操作
function git_fixup_commit() {
  if [[ -z $(git diff --cached --name-only) ]]; then
    echo "no staged files"
    git status -sb
    return 1
  fi

  local hash=$1
  if [[ -z $hash ]]; then
    hash=$(git log -1 --pretty=%H)
  fi

  git commit --fixup $hash

  # --autosquash 模式不支持非交互式 reabse, 需要通过环境变量控制
  # https://stackoverflow.com/questions/29094595/git-interactive-rebase-without-opening-the-editor#answer-29094904
  GIT_SEQUENCE_EDITOR=: git rebase -i $hash^ --autosquash
}

# 使用一个分支备份当前 git 修改
# 如果工作区是干净的，你还可以进行 commit message 重写
function git_create_branch_backup(){
  local new_branch="$(whoami)/backup/$(date +%Y-%m-%d-%H_%M_%S)"

  # 工作区是干净的
  if [[ -z $(git status --porcelain) ]]; then
    # 获取当前 commit message
    local commit_message=$(git log -1 --pretty=%B)

    git branch $new_branch

    if [[ -n $1 ]]; then
      git checkout $new_branch
      git commit --amend -m "$1" --no-verify --no-gpg-sign
      git checkout -
    fi

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

  if [[ -n $staged ]]; then
    git add $staged
  fi
}

# 批量删除分支, 支持 grep 参数，输入 y 确定删除
# usage: git_batch_delete_branch [grep]
function git_batch_delete_branch() {
  local branches=$(git branch --all | awk '{print $1}')
  local ignore_branches=$(echo "$branches" | grep -v -E '^(master|main|dev|test)$|^dev-|^release-|^remotes|\*')
  echo "$ignore_branches" | grep ${1-.} | xargs -n 1 -p git branch -D
}

# 解析 url 并添加 git remote, 如果是自己的仓库，则添加 origin
# usage: git_add_remote [url]
# 依赖
#   GITHUB_NAME 环境变量，用于判断是否是自己的仓库
function git_add_remote() {
  local url=$1
  local userName=$(echo $url | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')

  if [[ -z $userName ]]; then
    echo "invalid url"
    return 1
  fi

  # myself
  if [[ $userName == $GITHUB_NAME ]]; then
    userName="origin"
  fi

  local isExist=$(git remote | grep $userName)

  if [[ -n $isExist ]]; then
    echo "remote $userName already exists"
    return 1
  fi

  git remote add $userName $url

  echo -e "remote \033[32;1m$userName\033[0m added"

  echo -n -e "Do you want to fetch remote? [y/N]"
  read isFetch
  if [[ $isFetch == "y" ]]; then
    git fetch $userName
  fi
}

# 通过多个服务商列表获取当前 ip
# usage: get_ip [count]
function get_ip() {
  local services=(
    "https://api.ipify.org" # https://www.ipify.org/
    "https://api64.ipify.org"
    "https://ipinfo.io/ip" # https://ipinfo.io/
    "https://ifconfig.me/ip" # https://ifconfig.me/
  )

  local count=${1:-${#services[@]}}

  # split [0, count)
  local services=(${services[@]:0:$count})

  for service in ${services[@]}; do
    local ip=$(curl -s $service)
    if [[ -z $ip ]]; then
      echo -e "\033[31;1m$service\033[0m: \033[31;1mfailed\033[0m"
    else
      echo -e "\033[32;1m$service\033[0m: $ip"
    fi
  done
}

# 获取本地 ip
function get_ip_local(){
  ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'
}

# 生成二维码
function qrcode() {
  local input="$*"
  [ -z "$input" ] && local input="@/dev/stdin"
  curl -d "$input" https://qrcode.show
}

# 启动一个 http 服务，并生成二维码
# usage: start_server [dir] [port]
# 依赖
#   http-server: https://www.npmjs.com/package/http-server
function start_server() {
  local dir=${1:-.}
  local port=${2:-8000}

  local public_ip=$(get_ip 1 | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | head -n 1)
  local local_ip=$(get_ip_local | head -n 1)

  if [[ -n $public_ip ]]; then
    echo -e "\033[32;1mpublic ip\033[0m: $public_ip"
    qrcode "http://$public_ip:$port"
    echo "https://qrcode.show/http://$public_ip:$port" && echo
  fi

  if [[ -n $local_ip ]]; then
    echo -e "\033[32;1mlocal ip\033[0m: $local_ip"
    qrcode "http://$local_ip:$port"
    echo "https://qrcode.show/http://$local_ip:$port" && echo
  fi

  # start server: https://www.npmjs.com/package/http-server
  http-server $dir -p $port

}
