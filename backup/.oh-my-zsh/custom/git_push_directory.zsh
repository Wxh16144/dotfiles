# ==============================================================================
# Git Push Directory Tool
# 
# NOTE: This code is AI-generated.
# 
# 中文说明：
# 本脚本用于将指定目录作为根目录推送到远程分支（常用于发布 dist/public 目录）。
# 每次运行前需存在配置文件 .git_push_config，或者使用 init 生成。
# 执行成功后会自动删除配置文件，确保一次性使用。
# 采用暴力推送策略：新建临时仓库 -> 强制添加所有文件 -> 强制推送。
# ==============================================================================

# 辅助函数：色彩输出
function _git_push_dir_log() {
  local color=$1; shift
  local RED="\033[31;1m"
  local GREEN="\033[32;1m"
  local YELLOW="\033[33;1m"
  local RESET="\033[0m"
  
  case $color in
    red)    echo -e "${RED}[ERROR] $*${RESET}" ;;
    green)  echo -e "${GREEN}[SUCCESS] $*${RESET}" ;;
    yellow) echo -e "${YELLOW}[INFO] $*${RESET}" ;;
    *)      echo "$@" ;;
  esac
}

# 主函数
# usage: git_push_directory [init|run]
function git_push_directory() {
  local action=${1:-run}
  local config_file=".git_push_config"

  # ================= Init Mode =================
  if [[ "$action" == "init" ]]; then
    if [[ -f $config_file ]]; then
      _git_push_dir_log yellow "Config file ($config_file) already exists."
      echo -n "Edit it? [Y/n] "
      read choice
      if [[ "$choice" != "n" && "$choice" != "N" ]]; then
        ${EDITOR:-vi} $config_file
      fi
      return
    fi

    # 自动探测默认值
    local default_remote=$(git remote | head -n 1) # simple pick first remote
    [[ -z $default_remote ]] && default_remote="origin"
    
    local remote_url=$(git remote get-url $default_remote 2>/dev/null)
    
    local default_branch="gh-pages"
    local default_dir="dist"
    
    # 智能探测构建目录
    if [[ ! -d "dist" && -d "public" ]]; then
      default_dir="public"
    elif [[ ! -d "dist" && -d "build" ]]; then
      default_dir="build"
    elif [[ ! -d "dist" && -d "out" ]]; then
      default_dir="out"
    fi

    cat <<EOF > $config_file
[config]
# The directory to deploy (relative path)
source_dir=$default_dir

# Remote URL (e.g. git@github.com:user/repo.git)
# Auto-detected from: $default_remote
remote_url=$remote_url

# Target branch (will be FORCE pushed)
target_branch=$default_branch

# Commit message
commit_message=deploy: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    _git_push_dir_log green "Config file generated: ./$config_file"
    ${EDITOR:-vi} $config_file
    return
  fi

  # ================= Run Mode =================
  if [[ ! -f $config_file ]]; then
    _git_push_dir_log red "Config file not found: ./$config_file"
    _git_push_dir_log yellow "Run 'git_push_directory init' first."
    return 1
  fi

  # 简单的配置解析 (ini key=value)
  local source_dir=$(grep '^source_dir=' $config_file | cut -d'=' -f2- | tr -d ' ' | tr -d '\r')
  local remote_url=$(grep '^remote_url=' $config_file | cut -d'=' -f2- | tr -d ' ' | tr -d '\r')
  local target_branch=$(grep '^target_branch=' $config_file | cut -d'=' -f2- | tr -d ' ' | tr -d '\r')
  local commit_msg=$(grep '^commit_message=' $config_file | cut -d'=' -f2- | sed 's/^[ \t]*//;s/[ \t]*$//' | tr -d '\r')

  # 参数校验
  if [[ -z $source_dir ]]; then _git_push_dir_log red "source_dir is empty"; return 1; fi
  if [[ -z $remote_url ]]; then _git_push_dir_log red "remote_url is empty"; return 1; fi
  if [[ -z $target_branch ]]; then _git_push_dir_log red "target_branch is empty"; return 1; fi

  if [[ ! -d $source_dir ]]; then
    _git_push_dir_log red "Directory not found: $source_dir"
    return 1
  fi
  
  if [[ -z $(ls -A $source_dir) ]]; then
    _git_push_dir_log red "Directory is empty: $source_dir"
    return 1
  fi

  _git_push_dir_log yellow "Deploying $source_dir -> $target_branch ..."

  local current_dir=$(pwd)
  local tmp_dir=$(mktemp -d)
  
  # 复制文件 (使用 -L 跟随软链接，确保部署的是实体文件)
  # 使用 cp -R . 确保不会多一层目录
  cp -R -L "$source_dir/." "$tmp_dir"
  
  cd "$tmp_dir" || return 1

  # 初始化并提交
  git init -q
  git config user.name "$(git config --global user.name || echo 'deploy-bot')"
  git config user.email "$(git config --global user.email || echo 'deploy@bot.com')"

  # 强制添加所有文件 (忽略 .gitignore 全局忽略等)
  git add -A -f
  git commit -m "${commit_msg:-deploy}" -q --no-verify --no-gpg-sign
  
  # 强制推送
  _git_push_dir_log yellow "Pushing to remote ($remote_url)..."
  
  if git push "$remote_url" "HEAD:$target_branch" --force --quiet; then
    cd "$current_dir"
    /bin/rm -rf "$tmp_dir"
    
    # 成功逻辑
    _git_push_dir_log green "Deploy success!"
    
    # 尝试输出一个可点击的 URL
    local web_url=${remote_url/git@github.com:/https://github.com/}
    web_url=${web_url/.git/}
    echo -e "Remote: \033[4;34m$web_url/tree/$target_branch\033[0m"
    
    # 删除配置文件
    /bin/rm -f "$config_file"
    _git_push_dir_log yellow "Config file removed."
  else
    cd "$current_dir"
    /bin/rm -rf "$tmp_dir"
    _git_push_dir_log red "Push failed."
    return 1
  fi
}
