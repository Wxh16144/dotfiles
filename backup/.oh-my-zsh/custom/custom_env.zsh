# https://stackoverflow.com/a/65142525
export VISUAL=$ZSH_CUSTOM/shells/code-wait.sh
export EDITOR=$ZSH_CUSTOM/shells/code-wait.sh

export GITHUB_NAME="Wxh16144"


# MacOS applications
export APP=/Applications
# /Users/{username} => ~
export USER_APP=$HOME/Library/Application\ Support
# chrome://apps  PWA
export CHROME_APP=$HOME/Applications/Chrome\ Apps.localized
export ICLOUD=$HOME/Library/Mobile\ Documents/com~apple~CloudDocs

# https://support.apple.com/zh-cn/108809
export APPLE_BACKUP=$USER_APP/MobileSync/Backup

# 本地私有依赖包目录
export PKG=$ICLOUD/local_packages
# 主机本地离线备份（仅本机存储）
export LOCAL_BACKUP=$HOME/Backup_local
# iCloud常驻云端备份目录
export ICLOUD_BACKUP=$ICLOUD/Backup
# 每日自动执行备份任务输出目录，存放按日期划分的定时备份文件
export DAILY_BACKUP=$ICLOUD/daily_backups

# Increase Bash history size. Allow 32³ entries; the default is 1000.
export HISTSIZE='32768'
export HISTFILESIZE="${HISTSIZE}"

# https://stackoverflow.com/a/52755693/11302760
export HIST_STAMPS="%Y-%m-%d %H:%M:%S"

# 配置文件, 本地 Docker 配置、Dotfiles 仓库
export CONFIG="$HOME/Config"
# 个人脚本，crontab、raycast 等 
export SCRIPTS="$HOME/Scripts"
# 和代码有关
export WORKSPACE="$HOME/Code"

# 纯粹的公司项目
export COMPANY=$WORKSPACE/company
# 公司项目归档，仅归属于自己的项目（请不要放合同之内的项目，避免纠纷）
export COMPANY_ARCHIVE=$WORKSPACE/company_archive
# 开源项目
export OSS=$WORKSPACE/oss
# 大语言模型
export LLM=$WORKSPACE/llm
# 纯粹的自己的项目
export MY=$WORKSPACE/self
# 演练项目
export PLAY=$WORKSPACE/playground
# 比如 VSCode 的 workspace
export IDE_WORKSPACE=$WORKSPACE/workspace
# 本地数据文件夹, 一定得记得定期备份（不放 ICloud 是因为太大了）
export ARCHIVE=$HOME/Archive

# registry
# export COMPANY_NPM_REGISTRY="https://packages.aliyun.com/616ff38165b9775dd591fcc9/npm/npm-registry/"

# docker run -it --rm --name verdaccio -p ${SELF_NPM_PORT:-4873}:4873 verdaccio/verdaccio
export SELF_NPM_PORT="10188" 
export SELF_NPM_REGISTRY="http://x.wxhboy.cn:${SELF_NPM_PORT}/"
export LOCAL_NPM_REGISTRY="http://npm.test"
# export COMPANY_DOCKER_REGISTRY="https://example.com"

# git 备份上游 remote
export BACKUP_REMOTE_NAME="backup"

# ollama
# https://github.com/ollama/ollama/issues/2335
export OLLAMA_ORIGINS=*

# temp
# https://apple.stackexchange.com/a/22716
# https://iboysoft.com/wiki/tmp-folder-mac.html
export OSX_TMPDIR=$TMPDIR
export TMP=/var/tmp

# 临时日志文件, crontab 任务产生的日志
export LOGS=$TMP/$(whoami)-tmp-logs
export TMPPLAY=$TMP/$(whoami)-tmp-playground

# https://github.com/skywind3000/z.lua/blob/master/README.cn.md#options
export _ZL_NO_ALIASES=1
export _ZL_CMD="j"

# Allow to change the font size and font of the workbench 
# https://github.com/microsoft/vscode/issues/519#issuecomment-3691806331
export VSC_WORKBENCH_CSS_FILE=$APP/Visual\ Studio\ Code.app/Contents/Resources/app/out/vs/workbench/workbench.desktop.main.css

# VS Code work profile isolation
# 个人使用 VS Code 默认 profile；公司单独使用隔离的 user-data-dir / extensions-dir
export VSCODE_PROFILE_WORK_ROOT="$COMPANY/.vscode-profile"
export VSCODE_PROFILE_WORK_NAME="Work"
export VSCODE_PROFILE_WORK_USER_DATA="$VSCODE_PROFILE_WORK_ROOT/user-data"
export VSCODE_PROFILE_WORK_EXTENSIONS="$VSCODE_PROFILE_WORK_ROOT/extensions"

# ==================================================================
# ======================= DIRECTORY METADATA ========================
# ==================================================================
typeset -gA DIRECTORY_BADGES
DIRECTORY_BADGES=(
  [$COMPANY]="🏢"
  [$COMPANY_ARCHIVE]="🗄️"
  [$OSS]="🌐"
  [$LLM]="🤖"
  [$MY]="🏠"
  [$PLAY]="🎢"
  [$IDE_WORKSPACE]="💻"
  [$ARCHIVE]="📦"
  [$CONFIG]="🔧"
  [$SCRIPTS]="📜"
)

# ==================================================================
# ======================= ENSURE DIRECTORIES ========================
# ==================================================================
function __internal_ensure_dir() {
  local dirs=(
    $CONFIG
    $SCRIPTS
    $WORKSPACE
    $IDE_WORKSPACE
    $COMPANY
    $COMPANY_ARCHIVE
    $OSS
    $MY
    $LLM
    $PLAY
    # vscode work profile
    $VSCODE_PROFILE_WORK_ROOT
    $VSCODE_PROFILE_WORK_USER_DATA
    $VSCODE_PROFILE_WORK_EXTENSIONS
    # other
    $ARCHIVE
    $PKG
    $LOCAL_BACKUP
    $DAILY_BACKUP
    $LOGS
    $TMPPLAY
  )

  for dir in ${dirs[@]}; do
    if [ ! -d $dir ]; then
      mkdir -p $dir
    fi
  done

  local hidden_dirs=(
    $CONFIG
    $SCRIPTS
    $WORKSPACE
    $IDE_WORKSPACE
    $ARCHIVE
    $LOCAL_BACKUP
    $DAILY_BACKUP
    $VSCODE_PROFILE_WORK_ROOT
  )

  for dir in ${hidden_dirs[@]}; do
    chflags hidden $dir
  done

}

# ==================================================================
# ========================= ENSURE SYMLINKS =========================
# ==================================================================
function __internal_ensure_symlink() {
  # 定义二维数组 [实际目标, 软连接]
  declare -A symlinks
  
  symlinks=(
    [$TMPDIR]="${ICLOUD}/TMP_short"
    [$TMP]="${ICLOUD}/TMP_long"
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

# ==================================================================
# =========================== BOOTSTRAP =============================
# ==================================================================
__internal_ensure_dir
__internal_ensure_symlink
