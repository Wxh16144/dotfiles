# ==============================================================================
# VS Code Profile Tool
#
# 中文说明：
# 个人使用 VS Code 默认 profile；公司使用独立的 user-data-dir / extensions-dir，
# 隔离 Copilot 登录态、设置、插件与缓存。
# ==============================================================================

if [[ -z "$VSCODE_PROFILE_WORK_ROOT" ]]; then
  if [[ -n "$COMPANY" && -d "$COMPANY" ]]; then
    VSCODE_PROFILE_WORK_ROOT="$COMPANY/.vscode-profile"
  else
    VSCODE_PROFILE_WORK_ROOT="$HOME/.vscode-profile-work"
  fi
fi

: ${VSCODE_PROFILE_WORK_NAME:="Work"}
: ${VSCODE_PROFILE_WORK_USER_DATA:="$VSCODE_PROFILE_WORK_ROOT/user-data"}
: ${VSCODE_PROFILE_WORK_EXTENSIONS:="$VSCODE_PROFILE_WORK_ROOT/extensions"}

export VSCODE_PROFILE_WORK_ROOT
export VSCODE_PROFILE_WORK_NAME
export VSCODE_PROFILE_WORK_USER_DATA
export VSCODE_PROFILE_WORK_EXTENSIONS

function __vscode_profile_log() {
  local color=$1; shift
  local reset="\e[0m"
  case $color in
    red)    echo -e "\e[31m[ERROR] $@$reset" ;;
    green)  echo -e "\e[32m[SUCCESS] $@$reset" ;;
    yellow) echo -e "\e[33m[INFO] $@$reset" ;;
    *)      echo "$@" ;;
  esac
}

function __vscode_profile_code_bin() {
  local code_bin=$(whence -p code)
  if [[ -z "$code_bin" ]]; then
    __vscode_profile_log red "code command not found. Install VS Code shell command first."
    return 1
  fi

  echo "$code_bin"
}

function __vscode_profile_help() {
  cat <<'EOF'
Usage:
  vscode_work_profile [code-args...]

Examples:
  vscode_work_profile                 # open current directory with isolated work profile
  vscode_work_profile .               # open current directory with isolated work profile
  vscode_work_profile ~/Code/company  # open a work project with isolated work profile

Notes:
  - Daily usage should use the original code command.
  - This helper only manages the isolated work user-data-dir and extensions-dir.
  - Use VS Code Profiles UI to import, export, or sync profile settings.
  - Settings Sync is launched as off to avoid profile cross-contamination.
EOF
}

function __vscode_profile_ensure_dirs() {
  local dir
  for dir in "$@"; do
    [[ -d "$dir" ]] || mkdir -p "$dir"
  done
}

function __vscode_profile_ensure_work_dir() {
  local dirs=(
    "$VSCODE_PROFILE_WORK_ROOT"
    "$VSCODE_PROFILE_WORK_USER_DATA"
    "$VSCODE_PROFILE_WORK_EXTENSIONS"
  )

  __vscode_profile_ensure_dirs "${dirs[@]}"

  if command -v chflags &>/dev/null; then
    chflags hidden "$VSCODE_PROFILE_WORK_ROOT" 2>/dev/null
  fi
}

function vscode_work_profile() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    __vscode_profile_help
    return 0
  fi

  case "${1:l}" in
    work|w|company|corp|com)
      shift
      ;;
  esac

  local code_bin=$(__vscode_profile_code_bin) || return 1

  if [[ $# -eq 0 ]]; then
    set -- .
  fi

  __vscode_profile_ensure_work_dir
  __vscode_profile_log green "Opening VS Code work profile: $VSCODE_PROFILE_WORK_NAME"
  "$code_bin" \
    --user-data-dir "$VSCODE_PROFILE_WORK_USER_DATA" \
    --extensions-dir "$VSCODE_PROFILE_WORK_EXTENSIONS" \
    --profile "$VSCODE_PROFILE_WORK_NAME" \
    --sync off \
    "$@"
}

