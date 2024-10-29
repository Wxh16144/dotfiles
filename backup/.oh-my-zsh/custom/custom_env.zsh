# https://stackoverflow.com/a/65142525
export VISUAL=$ZSH_CUSTOM/shells/code-wait.sh
export EDITOR=$ZSH_CUSTOM/shells/code-wait.sh

export GITHUB_NAME="Wxh16144"

# /Users/{username} => ~
export APP=$HOME/Library/Application\ Support
# chrome://apps  PWA
export CHROME_APP=$HOME/Applications/Chrome\ Apps.localized
export ICLOUD=$HOME/Library/Mobile\ Documents/com~apple~CloudDocs

# local_packages
export PKG=$ICLOUD/local_packages

# Increase Bash history size. Allow 32³ entries; the default is 1000.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";

# my projects directory
export CONFIG="$HOME/Config"
export SCRIPTS="$HOME/Scripts"
export WORKSPACE="$HOME/Code"
# code directory
export COMPANY=$WORKSPACE/company
export OSS=$WORKSPACE/oss
export MY=$WORKSPACE/self
export PLAY=$WORKSPACE/playground

# registry
# export COMPANY_NPM_REGISTRY="https://packages.aliyun.com/616ff38165b9775dd591fcc9/npm/npm-registry/"
export SELF_NPM_REGISTRY="http://localhost:10017/"
# export COMPANY_DOCKER_REGISTRY="https://example.com"

# git backup
export BACKUP_REMOTE_NAME="backup"

# temp
# https://apple.stackexchange.com/a/22716
# https://iboysoft.com/wiki/tmp-folder-mac.html
export OSX_TMPDIR=$TMPDIR
export TMP=/var/tmp

# 临时日志文件, crontab 任务等
export LOGS=$TMP/$(whoami)-tmp-logs

# ====== footer ====== #
function __internal_ensure_dir() {
  local dirs=(
    $CONFIG
    $SCRIPTS
    $WORKSPACE
    $COMPANY
    $OSS
    $MY
    $PLAY
    # other
    $PKG
    $LOGS
  )

  for dir in ${dirs[@]}; do
    if [ ! -d $dir ]; then
      mkdir -p $dir
    fi
  done
}

function __internal_ensure_symlink() {

  # 定义二维数组 [实际目标, 软连接]
  declare -A symlinks
  
  symlinks=(
    [$TMPDIR]="${ICLOUD}/Temporary"
    [$TMP]="${ICLOUD}/Private_var_tmp"
    [$HOME/Desktop]="${ICLOUD}/Desktop"
    [$HOME/Documents]="${ICLOUD}/Documents"
    [$LOGS]="${ICLOUD}/$(whoami)-logs"
  )

  for target in ${(@k)symlinks}; do
    link=${symlinks[$target]}

    # 如果 link 存在，但是无效，则删除 link
    if [ -L $link ] && [ ! -e $link ]; then
      # print_yellow "Removing broken symlink: $link" 

      /bin/rm $link
    fi

    # 如果 target 存在, 但 link 不存在, 则创建 link
    if [ -d $target ] && [ ! -L $link ]; then
      # print_yellow "Creating symlink: $link -> $target" # 可作为调试用

      ln -s $target $link
    fi

  done
}

__internal_ensure_dir
__internal_ensure_symlink
