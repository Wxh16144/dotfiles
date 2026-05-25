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

# local_packages
export PKG=$ICLOUD/local_packages
export LOCAL_BACKUP=$HOME/Backup_local
export CLOUD_BACKUP=$ICLOUD/Backup

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

# ====== conditional env groups ====== #
# 控制变量约定: ENABLE_<GROUP_NAME>=1 则启用该组环境变量
function __register_env_group() {
  local name="${1:u}"
  shift
  typeset -ga "__ENV_GROUP_${name}"
  set -A "__ENV_GROUP_${name}" "$@"
}

# Directory badges
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

# ====== footer ====== #
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
    # other
    $ARCHIVE
    $PKG
    $LOCAL_BACKUP
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
  )

  for dir in ${hidden_dirs[@]}; do
    chflags hidden $dir
  done

}

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

function __internal_apply_env_groups() {
  local prefix="__ENV_GROUP_"
  local target="${1:u}"

  local -a available_groups=()
  for var in ${(k)parameters}; do
    [[ "$var" == ${prefix}* ]] || continue
    available_groups+=("${var#$prefix}")
  done

  _apply_group() {
    local -a pairs=("${(@P)1}")
    for pair in "${pairs[@]}"; do export "${(e)pair}"; done
  }

  if [[ -n $target ]]; then
    local var="${prefix}${target}"
    if [[ -z ${parameters[$var]} ]]; then
      echo "Group '${target}' not found. Available groups:"
      for g in ${available_groups[@]}; do echo "  - $g"; done
      return 1
    fi
    _apply_group $var
    echo "Applied env group: ${target}"
  else
    for g in ${available_groups[@]}; do
      local enable_var="ENABLE_${g}"
      [[ "${(P)enable_var}" == "1" ]] || continue
      _apply_group "${prefix}${g}"
    done
  fi

  unfunction _apply_group
}

# https://docs.ollama.com/integrations/claude-code#manual-setup
__register_env_group "OLLAMA_CC" \
  "ANTHROPIC_BASE_URL=http://localhost:11434" \
  "ANTHROPIC_AUTH_TOKEN=ollama" \
  "ANTHROPIC_MODEL=qwen3.5:9b"

# https://api-docs.deepseek.com/zh-cn/guides/coding_agents
__register_env_group "DS_CC" \
  "ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic" \
  'ANTHROPIC_AUTH_TOKEN=$OFFICIAL_DEEPSEEK_TOKEN' \
  "ANTHROPIC_MODEL=deepseek-v4-pro[1m]"

__internal_ensure_dir
__internal_ensure_symlink
__internal_apply_env_groups
