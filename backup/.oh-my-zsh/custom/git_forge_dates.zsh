# ==============================================================================
# Git History Date Tool (Git Date Forger)
# 
# NOTE: This code is AI-generated.
# 
# 中文说明：
# 本脚本用于修改 Git commit 的 AuthorDate 和 CommitterDate。
# 支持修改单个 commit 或根据配置文件批量随机化一段历史 commit 的时间分布。
# 每次操作前都会在 forge-backup/ 路径下创建备份 tag 以确保安全。
# ==============================================================================

# 辅助函数：色彩输出 (保持英文日志级别)
function _git_forge_log() {
  local color=$1; shift
  local reset="\e[0m"
  case $color in
    red)    echo -e "\e[31m[ERROR] $@$reset" ;;
    green)  echo -e "\e[32m[SUCCESS] $@$reset" ;;
    yellow) echo -e "\e[33m[INFO] $@$reset" ;;
    *)      echo "$@" ;;
  esac
}

# 内部函数：创建备份点
function _git_forge_create_backup() {
  local timestamp=$(date "+%Y%m%d_%H%M%S")
  local backup_name="forge-backup/$timestamp"
  # 将当前 HEAD 备份到一个特定的 tag 作用域
  if git tag "$backup_name" HEAD; then
    _git_forge_log yellow "Backup created: $backup_name"
    _git_forge_log yellow "To restore, run: git reset --hard $backup_name"
    return 0
  else
    _git_forge_log red "Failed to create backup. Aborting."
    return 1
  fi
}

# 修改指定 commit 的日期
# usage: git_change_date [commit] [date]
function git_change_date() {
  # 检查工作区状态
  if [[ -n $(git status --porcelain) ]]; then
    _git_forge_log red "Current workspace is dirty, please save or stash first."
    return 1
  fi

  local hash=$1
  local date=$2

  # 适配参数: 如果第二个参数为空，尝试判断第一个参数是否为日期
  if [[ -z $date ]]; then
    if git rev-parse --verify "$1^{commit}" >/dev/null 2>&1; then
       _git_forge_log red "Please input the date."
       return 1
    else
       date=$1
       hash="HEAD"
    fi
  fi

  # 验证提交是否存在
  if ! git rev-parse --verify "$hash^{commit}" >/dev/null 2>&1; then
    _git_forge_log red "Invalid commit: $hash"
    return 1
  fi

  # 执行前创建备份
  _git_forge_create_backup || return 1

  local full_hash=$(git rev-parse "$hash")
  local short_hash=$(git rev-parse --short "$full_hash")
  local head_hash=$(git rev-parse HEAD)

  _git_forge_log yellow "Changing date of commit $short_hash to $date..."

  if [[ "$full_hash" == "$head_hash" ]]; then
    # 如果是 HEAD，直接 amend
    GIT_COMMITTER_DATE="$date" git commit --amend --no-edit --no-verify --date "$date"
  else
    # 如果是历史提交，使用 rebase exec 注入修改命令
    local cmd="GIT_COMMITTER_DATE=\"$date\" git commit --amend --no-edit --no-verify --date \"$date\""
    
    # 构造临时编辑器脚本
    local editor_sh="${TMPDIR:-/tmp}/git_rebase_editor_$$"
    echo "#!/bin/sh\nperl -i -pe 's/^pick $short_hash.*/\$&\nexec $cmd/' \"\$1\"" > "$editor_sh"
    chmod +x "$editor_sh"
    
    GIT_SEQUENCE_EDITOR="$editor_sh" git rebase -i "${full_hash}^"
    rm "$editor_sh"
  fi
  
  _git_forge_log green "Job done."
}

# 批量修改 git commit 日期
# usage: git_forge_dates [init|run]
function git_forge_dates() {
  local action=${1:-run}
  local config_file="${TMPDIR:-/tmp}/git_forge_dates.ini"

  # 初始化配置模式
  if [[ "$action" == "init" ]]; then
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      _git_forge_log red "Not a git repository."
      return 1
    fi

    local head_hash=$(git rev-parse HEAD)
    # 获取最近 5 个或 root commit 作为默认范围
    local start_hash=$(git rev-parse HEAD~5 2>/dev/null || git rev-list --max-parents=0 HEAD | tail -n 1)
    
    cat <<EOF > $config_file
[config]
# The starting commit hash (oldest)
start_commit=$start_hash
# The ending commit hash (newest)
end_commit=$head_hash
# Date format: YYYY-MM-DD HH:MM:SS
start_date=$(date "+%Y-%m-%d 09:30:00")
end_date=$(date "+%Y-%m-%d %H:%M:%S")
# Work hours (24h format)
work_hours=10-19
EOF
    _git_forge_log green "Config file generated at $config_file"
    ${EDITOR:-vi} $config_file
    return
  fi

  # 执行修改模式
  if [[ ! -f $config_file ]]; then
    _git_forge_log red "Config file not found: $config_file"
    _git_forge_log yellow "Run 'git_forge_dates init' first."
    return 1
  fi
  
  if [[ -n $(git status --porcelain) ]]; then
    _git_forge_log red "Current workspace is dirty."
    return 1
  fi

  # 解析 ini 配置文件
  local start_commit=$(awk -F '=' '/^start_commit/{print $2}' $config_file | tr -d ' ')
  local end_commit=$(awk -F '=' '/^end_commit/{print $2}' $config_file | tr -d ' ')
  local start_date=$(awk -F '=' '/^start_date/{print $2}' $config_file | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  local end_date=$(awk -F '=' '/^end_date/{print $2}' $config_file | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  local work_hours=$(awk -F '=' '/^work_hours/{print $2}' $config_file | tr -d ' ')
  
  local work_start=$(echo $work_hours | cut -d'-' -f1)
  local work_end=$(echo $work_hours | cut -d'-' -f2)

  # 校验 commit 范围
  git merge-base --is-ancestor $start_commit $end_commit || { _git_forge_log red "Commit range error."; return 1; }

  # 执行前备份
  _git_forge_create_backup || return 1

  # 获取待修改的 commit 列表 (Zsh 语法按行转数组)
  local range="${start_commit}^..${end_commit}"
  git rev-parse --verify "${start_commit}^" >/dev/null 2>&1 || range="${end_commit}"
  local commits=(${(f)"$(git rev-list --reverse $range)"})
  local count=${#commits}
  
  _git_forge_log yellow "Found $count commits to modify."

  # 使用 Python 生成随机递增的时间序列
  local python_script="
import sys, random
from datetime import datetime, timedelta
s = datetime.strptime('$start_date', '%Y-%m-%d %H:%M:%S')
e = datetime.strptime('$end_date', '%Y-%m-%d %H:%M:%S')
ws, we = int('$work_start'), int('$work_end')
dates = []
while len(dates) < $count:
    days_diff = (e.date() - s.date()).days
    curr_day = s.date() + timedelta(days=random.randint(0, max(0, days_diff)))
    dt = datetime.combine(curr_day, datetime.min.time()).replace(hour=random.randint(ws, we - 1), minute=random.randint(0, 59), second=random.randint(0, 59))
    if s <= dt <= e: dates.append(dt)
dates.sort()
for d in dates: print(d.strftime('%Y-%m-%d %H:%M:%S'))
"
  local dates_str=$(python3 -c "$python_script")
  local dates=(${(f)dates_str})

  # 构建 rebase 序列编辑器脚本
  local todo_editor="${TMPDIR:-/tmp}/git_forge_todo_editor_$$"
  echo "#!/bin/zsh\nfile=\$1" > $todo_editor
  
  for i in {1..$count}; do
    local h=${commits[$i]}
    local d=${dates[$i]}
    local short_h=$(git rev-parse --short $h)
    local cmd="GIT_COMMITTER_DATE=\"$d\" git commit --amend --no-edit --no-verify --date \"$d\""
    echo "perl -i -pe 's/^pick $short_h.*/\$&\nexec $cmd/' \"\$file\"" >> $todo_editor
  done
  
  chmod +x $todo_editor

  # 执行 rebase 操作
  local base_ref="${start_commit}^"
  git rev-parse --verify "$base_ref" >/dev/null 2>&1 || base_ref="--root"

  _git_forge_log yellow "Starting rebase..."
  GIT_SEQUENCE_EDITOR=$todo_editor git rebase -i $base_ref

  rm $todo_editor
  _git_forge_log green "Good job."
}
