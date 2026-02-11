# ==============================================================================
# Git Worktree Tool
#
# NOTE: This code is AI-generated.
#
# 中文说明：
# 本脚本用于快速创建 git worktree 并自动同步环境配置文件。
# 支持在从主仓库创建 worktree 时，将 .env 等配置文件复制到新的 worktree 中。
# ==============================================================================

# 定义 worktree 目录的后缀名，例如 .worktrees 或 .workspace
GIT_WORKTREE_DIR_SUFFIX=".worktrees"

# 辅助函数：色彩输出
function _git_worktree_log() {
  local color=$1; shift
  local reset="\e[0m"
  case $color in
    red)    echo -e "\e[31m[ERROR] $@$reset" ;;
    green)  echo -e "\e[32m[SUCCESS] $@$reset" ;;
    yellow) echo -e "\e[33m[INFO] $@$reset" ;;
    *)      echo "$@" ;;
  esac
}

# 复制一些约定的配置/环境文件到指定目录
# usage: git_copy_common_files <target-dir> [source-dir]
function git_copy_common_files() {
  local target_dir=$1
  local src_dir=${2:-$(pwd)}

  [[ -z $target_dir ]] && { _git_worktree_log red "Please input target directory."; return 1; }

  # 开启 local_options 确保 nullglob 只在函数内有效
  setopt local_options nullglob

  # 定义匹配模式（基于源目录的绝对路径）
  local candidates=(
    "$src_dir"/.env
    "$src_dir"/.env.*
    # 如果有其他约定文件，可以在此继续添加，例如：
    # "$src_dir"/config/local.js
  )

  # 过滤不存在的文件 (比如 .env 这种没有通配符的 pattern 不会被 nullglob 过滤)
  local files=()
  for f in "${candidates[@]}"; do
    [[ -f "$f" ]] && files+=("$f")
  done

  # 如果没有找到任何匹配文件，直接静默退出
  (( ${#files} == 0 )) && return

  _git_worktree_log yellow "Found common files in ${src_dir:t}:"
  for f in "${files[@]}"; do
    echo "  ${f:t}"
  done

  # 使用 read -q 提高交互效率，y/n 无需回车
  echo -n -e "\e[33m[INFO] Copy these to ${target_dir}? [y/N] \e[0m"
  if read -q; then
    echo # 换行
    for f in "${files[@]}"; do
      # 计算相对路径，处理子目录拷贝
      local rel_path=${f#$src_dir/}
      local dest="$target_dir/$rel_path"

      # ${dest:h} 相当于 dirname，确保父目录存在
      mkdir -p "${dest:h}"
      if cp -p "$f" "$dest"; then
        _git_worktree_log green "Copied: $rel_path"
      else
        _git_worktree_log red "Failed to copy: $rel_path"
      fi
    done
  else
    echo # 即使不复制也换行，保持终端整洁
  fi
}

# 功能：快速创建 git worktree 并处理配置同步
# 用法：git_worktree_easy [-b <new-branch>] <branch> [args...]
function git_worktree_easy() {
  if [[ -z $(git rev-parse --is-inside-work-tree 2>/dev/null) ]]; then
    _git_worktree_log red "Not a git repository."
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    echo "Usage: git_worktree_easy [-b <new-branch>] <branch/commit-ish> [git-worktree-args...]"
    return 1
  fi

  # 1. 锁定当前主仓库的根目录（作为拷贝源）
  local current_main_root=$(git rev-parse --show-toplevel)

  # 2. 解析分支名用于生成目录名
  local target_branch=""
  for arg in "$@"; do
    [[ "$arg" != -* ]] && target_branch="$arg" && break
  done

  [[ -z $target_branch ]] && { _git_worktree_log red "Could not determine branch name."; return 1; }

  # 3. 计算 Worktree 存储路径
  local git_common_dir=$(git rev-parse --git-common-dir)
  # Handle both main repo and worktree cases to find the real root repo container
  # 使用 :A (absolute path) 和 :h (headdir) 修饰符获取绝对路径，避免 cd 触发 chpwd 钩子导致输出污染
  local main_repo_path="${git_common_dir:A:h}"
  
  local repo_name=$(basename "$main_repo_path")
  local parent_dir=$(dirname "$main_repo_path")

  local safe_branch=$(echo "$target_branch" | sed 's/\//-/g')
  local worktree_path="$parent_dir/${repo_name}${GIT_WORKTREE_DIR_SUFFIX}/${safe_branch}"

  if [[ -e $worktree_path ]]; then
    _git_worktree_log red "Path already exists: $worktree_path"
    return 1
  fi

  # 4. 执行创建
  _git_worktree_log green "Creating worktree at: $worktree_path"
  git worktree add "$worktree_path" "$@"

  if [[ $? -eq 0 ]]; then
    _git_worktree_log green "Worktree created successfully!"

    # 5. 调用拷贝函数，显式传入源目录防止路径丢失
    git_copy_common_files "$worktree_path" "$current_main_root"

    # 6. 询问是否进入新目录
    echo -n -e "\e[33m[INFO] Do you want to cd into the worktree? [y/N] \e[0m"
    if read -q; then
      echo
      cd "$worktree_path"
    else
      echo
    fi
  fi
}

# 自动清理空的 workspace 目录的 hook
function _git_worktree_cleanup_hook() {
  # 仅在 Git 主仓库根目录触发 (跳过 worktree 和非 git 目录)
  [[ -d ".git" ]] || return

  # 推算同级 workspace 目录 (当前目录名 + 后缀，位于上级目录)
  local workspace_dir="../${PWD:t}${GIT_WORKTREE_DIR_SUFFIX}"

  # 如果目录存在，直接尝试删除
  # 安全性提示：rmdir 命令仅在目录完全为空时才会执行删除
  # 如果目录非空（包含任何文件），rmdir 会失败并跳过，不会造成数据丢失
  if [[ -d "$workspace_dir" ]]; then
    if rmdir "$workspace_dir" 2>/dev/null; then
      _git_worktree_log yellow "Removed empty workspace directory: ${workspace_dir:t}"
    fi
  fi
}

# 注册 chpwd hook，在切换目录时触发
autoload -U add-zsh-hook
add-zsh-hook chpwd _git_worktree_cleanup_hook
