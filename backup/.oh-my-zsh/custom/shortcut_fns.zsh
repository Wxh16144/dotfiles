local RED="\033[31;1m"
local GREEN="\033[32;1m"
local YELLOW="\033[33;1m"
local RESET="\033[0m"

print_red() {
  echo -e "${RED}$*${RESET}"
}
print_green() {
  echo -e "${GREEN}$*${RESET}"
}

# ==================== Functions ====================

# 在当前目录中打开 fork 应用程序
# https://git-fork.com/
function open_fork() {
  if is_git_repository; then
    # 得到当前 git 仓库的根目录
    local rootDir=$(git rev-parse --show-toplevel)
    open -a Fork $rootDir
  else
    print_red "Not a git repository."
  fi
}

# 判断 package.json 中是否存在指定的 script
function has_script() {
  [[ $(npm run | grep "^  $1$" | wc -l) -eq 1 ]]
}

function _fe_run_script() {
  echo -e "${GREEN}Current project start method: ${YELLOW}$*${RESET}"
  # execute the input command
  eval $*
}

# 判断并启动前端工程化项目
# 依赖
#   - nr: https://github.com/wxh16144/ni
function start_fe_project() {
  if has_script start; then
    _fe_run_script $(nr start "?")
  elif has_script dev; then
    _fe_run_script $(nr dev "?")
  else
    print_red "No dev or start script found."
  fi
}

# 判断并且编译前端工程化项目
# 依赖
#   - nr: https://github.com/wxh16144/ni
function compile_fe_peoject() {
  if has_script build; then
    _fe_run_script $(nr build "?")
    good_job
  elif has_script compile; then
    _fe_run_script $(nr compile "?")
  else
    print_red "No build or compile script found."
  fi
}

# 设置 npm、yarn 的 registry
function set_registry() {
  local registry=$1
  npm config set registry $registry
  yarn config set registry $registry
  print_green "Set registry to $registry"
}

# 管理 npm registry
# useage: npm_registry_manage [registry]
# 依赖
#   - na: https://github.com/wxh16144/ni
#   - COMPANY_NPM_REGISTRY 环境变量
#   - MY_NPM_REGISTRY 环境变量
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
  )

  if [[ -n $COMPANY_NPM_REGISTRY ]]; then
    registrys[company]=$COMPANY_NPM_REGISTRY
  fi

  if [[ -n $MY_NPM_REGISTRY ]]; then
    registrys[self]=$MY_NPM_REGISTRY
  fi

  # 如果没有参数, 则表示查看当前 registry，并且询问是否要重置为默认 registry [npm]
  if [ $# -eq 0 ]; then
    print_green "Current registry: $(npm config get registry)"

    echo -n -e "${YELLOW}Reset to default registry[npm]? [y/n] ${RESET}"
    read agreeReset
    if [ $agreeReset = "y" ]; then
      set_registry ${registrys[npm]}
    fi
    return
  fi

  # 判断输入的 registry 是否存在
  if [ -z ${registrys[$input_registry]} ]; then
    if [[ $input_registry != "h" && $input_registry != "help" && $input_registry != "ls" ]]; then
      print_red "Registry $input_registry not found."
    fi

    print_green "Available registrys:"

    for key in ${(@k)registrys}; do
      echo -e " ${RED}$key: ${YELLOW}${registrys[$key]}${RESET}";
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
# 这里的删除使用的是 /bin/rm, 而不是 trash, 因为 trash 会将文件移动到回收站, 但是 node_modules 通常会很大, 会占用很多空间
function remove_node_modules() {
  local nm=$(list_node_modules)
  if [[ $1 == "-a" ]]; then
    echo $nm | xargs -n 1 /bin/rm -rf
    print_green "All node_modules have been removed."
  else
    echo $nm | xargs -n 1 -p /bin/rm -rf
  fi
}

# 删除当前目录所有文件(危险操作)
function remove_all_files() {
  local currentDir=${1:-$(pwd)}
  local parentDir=$(dirname $currentDir)
  local files=()

  # 如果当前项目是软链接，则删除源文件
  if [[ -L $currentDir ]]; then
    print_red "$currentDir is a symbolic link, will remove the source file."
    # 将软连接本身添加到待删除列表
    files+=($currentDir)
    currentDir=$(readlink $currentDir)
  fi

  files+=($currentDir)

  echo -n -e "${YELLOW}Are you sure to remove all files in ${RED}$currentDir${RESET}? [y/n] "
  read agreeRemove
  if [ $agreeRemove = "y" ]; then
    for file in ${files[@]}; do
      # 如果文件是在临时目录中或者是软连接，则直接删除，否则移动到回收站
      if [[ $file =~ $TMPDIR || -L $file ]]; then
        /bin/rm -rf $file
      else
        trash $file
      fi
    done
    echo "All files have been removed."
    # 判断上一条记录地址是否存在，如果存在则进入，否则进入 ../
    if [[ -d $OLDPWD ]]; then
      cd $OLDPWD
    else
      cd $parentDir
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
  local cloneDir=${2:-$(basename $1 .git)}

  [[ -d $cloneDir/.git ]] || git clone --recurse-submodules "$@"
  
  cd $cloneDir
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
#   - GITHUB_NAME 环境变量(自己的 github 用户名) + -forks (用于存放 fork 的项目)
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
    # https://twitter.com/Wxh16144/status/1737664681786093885
    git remote set-url origin "git@github.com:$GITHUB_NAME-forks/$repoName.git"

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

  git commit --fixup $hash --no-verify

  # --autosquash 模式不支持非交互式 reabse, 需要通过环境变量控制
  # https://stackoverflow.com/questions/29094595/git-interactive-rebase-without-opening-the-editor#answer-29094904
  GIT_SEQUENCE_EDITOR=: git rebase -i $hash^ --autosquash
}

# 使用一个分支备份当前 git 修改
# 如果工作区是干净的，你还可以进行 commit message 重写
# 输入 -r 可以备份到远端
function git_create_branch_backup(){
  local new_branch="$(whoami)/backup/$(date +%Y-%m-%d-%H_%M_%S)"

  # 写入环境变量
  export MY_LATEST_BACKUP_BRANCH=$new_branch

  function try_push_backup_to_remote(){
    # -r 参数表示推送到远端(如果在公司项目则默认推送到远端)
    if [[ $1 == "-r" || $(pwd) =~ $COMPANY ]]; then
      echo -e "${YELLOW}Will try to push to backup...${RESET}"
      push_backup_to_remote $new_branch
    fi
  }

  # 工作区是干净的
  if [[ -z $(git status --porcelain) ]]; then
    # 获取当前 commit message
    local commit_message=$(git log -1 --pretty=%B)

    git branch $new_branch

    if [[ -n $1 && $1 != "-r" ]]; then
      git checkout $new_branch
      git commit --amend -m "$1" --no-verify --no-gpg-sign
      git checkout -
    fi

    echo -e "The current workspace is clean, and a new branch:${GREEN}${new_branch}${RESET} is created"
    try_push_backup_to_remote $1
    return 1
  fi

  local branch=$(git rev-parse --abbrev-ref HEAD)
  local short_hash=$(git rev-parse --short HEAD)

  local staged=$(git diff --cached --name-only)
  # local unstaged=$(git diff --name-only)

  git add -A
  git commit --no-verify --no-gpg-sign -m "$(cat <<EOF
WIP chore: backup on ${branch}(${short_hash}) [skip-ci]

- branch: ${branch}
- date: $(date +%Y-%m-%d\ %H:%M:%S)
- commit: $(git rev-parse HEAD)

---------- original commit message ----------

$(git log -1 --pretty=%B)

EOF
)"

  git checkout -b $new_branch

  git checkout $branch
  git reset --mixed HEAD^

  if [[ -n $staged ]]; then
    git add $staged
  fi

  try_push_backup_to_remote $1

  good_job
}

function is_git_repository() {
  if [[ -z $(git rev-parse --is-inside-work-tree 2>/dev/null) ]]; then
    return 1
  fi
}

# 推送备份分支到远端
# 前置依赖 BACKUP_REMOTE_NAME 环境变量
function push_backup_to_remote(){
  if ! is_git_repository; then
    print_red "not a git repository, skip push"
    return
  fi

  local backup_branch=${1:-$MY_LATEST_BACKUP_BRANCH}
  if [[ -z $backup_branch || -z $BACKUP_REMOTE_NAME ]]; then
    print_red "backup_branch or BACKUP_REMOTE_NAME not found, skip push"
    return
  fi

  # 判断要备份的分支是否存在
  if [[ -z $(git branch -a | grep $backup_branch) ]]; then
    print_red "branch > $backup_branch < not found, skip push"
    return
  fi
  
  # 判断当前仓库是否存在 $BACKUP_REMOTE_NAME remote
  if [[ -z $(git remote | grep $BACKUP_REMOTE_NAME) ]]; then
    print_red "remote > $BACKUP_REMOTE_NAME < not found, skip push"
    return
  fi

  # 检查远程仓库的连接状态
  local remote_url=$(git remote get-url $BACKUP_REMOTE_NAME);
  if [[ -z $(git ls-remote --exit-code $remote_url) ]]; then
    print_red "remote > $BACKUP_REMOTE_NAME:$remote_url < is not available, skip push"
    return
  fi

  # 推送到 backup, 默认强制推送, 并且不执行任何 hook
  git push $BACKUP_REMOTE_NAME $backup_branch --force --no-verify
  
  if [[ $? -eq 0 ]]; then
    print_green "push $backup_branch success"
    # 删除环境变量
    unset MY_LATEST_BACKUP_BRANCH
  else
    print_red "push $backup_branch failed"
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
    print_red "invalid url"
    return 1
  fi

  # myself
  if [[ $userName == $GITHUB_NAME* ]]; then
    userName="origin"
  fi

  local isExist=$(git remote | grep $userName)

  if [[ -n $isExist ]]; then
    print_red "remote $userName already exists"
    return 1
  fi

  git remote add $userName $url

  echo -e "remote ${GREEN}$userName${RESET} added"

  echo -n -e "${YELLOW}Do you want to fetch remote? [y/N]${RESET}"
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
      echo -e "${RED}$service${RESET}: ${RED}failed${RESET}"
    else
      echo -e "${GREEN}$service${RESET}: $ip"
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

# 快速创建一个 server
# 前置条件：
# 1. 安装了 nodejs 和 http-server， see：https://www.npmjs.com/package/http-server
# 2. 本地已经安装了 ngrok, 并且已经完成配置 see：https://ngrok.com/download
# 3. 本地安装了 jq, see: https://jqlang.github.io/jq/
# 4. 一些我的前置函数 qrcode、get_ip_local
# example:
# quick_server # 默认当前目录 端口 8888
# quick_server coverage
function quick_server() {
  local port=${PORT:-$2}
  local dir=${1:-.}

  # Fallback to default port
  if [[ -z $port ]]; then
    port=8888
  fi

  # Check for port availability
  if [[ -n $(lsof -i :$port) ]]; then
    echo -e "${RED}Port $port is occupied.${RESET}, check ${GREEN}lsof -i tcp:$port${RESET}"
    return 1
  fi

  local local_ip=$(get_ip_local | head -n 1)
  if [[ -n $local_ip ]]; then
    echo -e "${GREEN}Local URL${RESET}: http://$local_ip:$port"
    qrcode "http://$local_ip:$port"
    echo "https://qrcode.show/http://$local_ip:$port" && echo
  fi

  # 杀死所有的 ngrok 进程(不在乎误杀)
  killall_ngrok() {
    killall ngrok
  }
  trap killall_ngrok EXIT # 在退出时也杀死

  if [[ -z $NGROK_DISABLED && -x $(command -v ngrok) ]]; then
    killall_ngrok
    # Start ngrok
    ngrok http $port >/dev/null 2>&1 &
    # Wait for ngrok to start
    sleep 3
    # Get ngrok URL
    local ngrok_url=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    echo -e "${GREEN}Ngrok URL${RESET}: $ngrok_url"
    qrcode $ngrok_url
    # Echo inspect URL
    echo -e "${YELLOW}Inspect URL${RESET}: http://localhost:4040"
    echo "https://qrcode.show/$ngrok_url" && echo
  fi

  # Start server using http-server
  http-server $dir -p $port
}

# 基于 quick_server 的一个快速创建一个 private server (不使用 ngrok)
function private_server() {
  # Define a trap to clean up environment variables on function termination
  cleanup() {
    unset NGROK_DISABLED
  }
  trap cleanup EXIT

  # Set environment variables
  export NGROK_DISABLED=true

  # Start server
  quick_server $@
}

# 统计指定目录下的当个文件行数并排序[降序](Top 300)（默认忽略 node_modules, .git, dist 目录）
# usage: count_lines [dir]
function count_lines(){
  # https://stackoverflow.com/a/316613/11302760
  find ${1:-.} -type f -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -print0 | xargs -0 wc -l | sort -rn | head -n 300
}

# 将指定目录推送到远程仓库
function push_ignored_directory() {
  local igored_dir=${1:-dist}
  local branch=${2:-gh-pages}
  local remote_name=${3:-origin}
  local force=${4:-false}
  local current_dir=$(pwd)

  local remote_url=$(git remote get-url $remote_name)

  # ----------------- check remote start -----------------
  if [[ -z $remote_url ]]; then
    echo -e "${RED}$remote_name${RESET} is not a remote name"
    return 1
  fi

  # ----------------- check dir start ----------------- 
  if [[ ! -d $igored_dir ]]; then
    echo -e "${RED}$igored_dir${RESET} is not a directory"
    return 1
  fi
  if [[ -z $(ls -A $igored_dir) ]]; then
    echo -e "${RED}$igored_dir${RESET} is empty"
    return 1
  fi
  if [[ -d $igored_dir/.git ]]; then
    echo -e "${RED}$igored_dir${RESET} is a git repository"
    return 1
  fi
  
  # ----------------- action -----------------
  local tmp_dir=$(mktemp -d)

  cp -R $igored_dir/. $tmp_dir
  cd $tmp_dir

  git init
  git add -A
  git commit -m "init" --no-verify --no-gpg-sign
  git remote add origin $remote_url
  local tmp_current_branch=$(git symbolic-ref --short HEAD)
  if [[ $force == "true" ]]; then
    git push origin $tmp_current_branch:$branch --force
  else
    git push origin $tmp_current_branch:$branch
  fi

  cd $current_dir
  # rm -rf $tmp_dir
  /bin/rm -rf $tmp_dir

  echo -e "${GREEN}$igored_dir${RESET} pushed to ${GREEN}$remote_url${RESET} => ${GREEN}$branch${RESET}"
}

# 查找并删除无效软连接
function find_and_remove_broken_links() {
    local dir=${1:-.}
    for link in $(find -L $dir -maxdepth 1 -type l); do
        if [ ! -e "$link" ]; then
            # rm "$link"
            /bin/rm "$link" # 软连接在我看来可以直接使用 /bin/rm
        fi
    done
}

# 生成的四位 hashid
function generate_short_hash() {
    length=4
    hash=$(openssl rand -hex $((length / 2)))
    hashid=$(echo $hash | cut -c1-$length)
    echo $hashid
}

# 创建一个临时文件夹，然后软连接到 $PLAY 目录， 可以输入一个参数作为目录名
function create_tmp_dir() {
  find_and_remove_broken_links
  local fallback_dir="$(whoami)_tmp_$(generate_short_hash)"
  local dirname=${1:-$fallback_dir}
  local tmp_dir="$TMPDIR$dirname"

  # 如果不是自定义目录，且存在则重新生成
  if [[ $dirname == $fallback_dir && -d $tmp_dir ]]; then
    create_tmp_dir
    return
  fi
  
  mkdir -p $tmp_dir

  # 软连接地址
  local link_dir="$PLAY/$dirname"

  # 建立软连接到 $PLAY 目录
  ln -s $tmp_dir $link_dir
  cd $link_dir
}

# 打印链接 see: https://link.wxhboy.cn/3Pja
function print_terminal_link() {
  local url=${1:-$(pwd)}
  local title=${2:-$url}
  echo -e "\033]8;;$url\a$title\033]8;;\a"
}

# 重新安装依赖
# 前置依赖 remove_node_modules, npm_registry_manage, auto-install-pnpm, ni
function re-install-fe-deps() {
  echo "${YELLOW}Please wait patiently...${RESET}"
  remove_node_modules -a
  npm_registry_manage taobao
  auto-install-pnpm
  ni
  good_job
}

# 将项目 clone 到临时目录(不克隆提交历史），并且建立软连接到 $PLAY 目录
# 前置依赖 create_tmp_dir
function clone_to_tmp_dir() {
  local repo=$1
  local dirname=$(basename $repo .git)
  create_tmp_dir "$(whoami)_clone_$dirname"
  clone_and_cd $repo $(pwd) --depth=1 # 既然是临时的，默认不克隆提交历史
}

# good job
# 前置：raycastapp
# https://www.raycast.com/changelog/1-35-0, https://manual.raycast.com/deeplinks
function good_job() {
  if [[ $? -eq 0 ]]; then
    open "raycast://confetti"
  fi
}
