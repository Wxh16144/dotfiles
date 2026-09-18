# ==============================================================================
# Env File Editor
#
# NOTE: This code is AI-generated.
#
# 不打开编辑器，直接在命令行读 / 改 / 删 env 文件里的某个条目：
#
#   env_get   KEY [file]        # 打印值
#   env_set   KEY VALUE [file]  # 有则改；没有则询问是否追加
#   env_unset KEY [file]        # 删除该行
#
# file 省略时按 $ENV_FILE → .env.local → .env 的顺序取第一个存在的。
# 只重写命中的那一行，保留 `export ` 前缀、引号风格和行尾注释。
# ==============================================================================

function _env_edit_log() {
  local color=$1; shift
  case $color in
    red)   print -u2 -P "\e[31m[ERROR] $*\e[0m" ;;
    green) print -u2 -P "\e[32m[OK] $*\e[0m" ;;
    *)     print -u2 -P "\e[33m[INFO] $*\e[0m" ;;
  esac
}

function _env_edit_check_key() {
  [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && return 0
  _env_edit_log red "Invalid key: $1"
  return 1
}

# 解析目标文件：显式参数 > $ENV_FILE > .env.local > .env
function _env_edit_file() {
  local file=$1

  if [[ -n $file ]]; then
    [[ -f $file ]] || { _env_edit_log red "No such env file: $file"; return 1 }
  elif [[ -n $ENV_FILE ]]; then
    file=$ENV_FILE
    [[ -f $file ]] || { _env_edit_log red "\$ENV_FILE points to a missing file: $file"; return 1 }
  elif [[ -f .env.local ]]; then
    file=.env.local
  elif [[ -f .env ]]; then
    file=.env
  else
    _env_edit_log red "No env file found (tried .env.local, .env)."
    return 1
  fi

  print -r -- "$file"
}

# 拆一行：把 "  export KEY=value # note" 分成 前缀/值/后缀/去引号值，写入 reply
# 返回非 0 表示这一行不是 KEY 的定义
function _env_edit_split() {
  setopt local_options extended_glob
  local line=$1 key=$2

  # 保留原始缩进，再剥掉可选的 `export `
  local prefix=${line%%[^[:space:]]*}
  local stripped=${line##[[:space:]]##}
  if [[ $stripped == export[[:space:]]##* ]]; then
    prefix+='export '
    stripped=${stripped#export}
    stripped=${stripped##[[:space:]]##}
  fi
  [[ $stripped == ${key}=* ]] || return 1

  local rest=${stripped#${key}=} quoted unwrapped
  if [[ $rest == \"* ]]; then
    unwrapped=${rest#\"}; unwrapped=${unwrapped%%\"*}
    quoted="\"${unwrapped}\""
  elif [[ $rest == \'* ]]; then
    unwrapped=${rest#\'}; unwrapped=${unwrapped%%\'*}
    quoted="'${unwrapped}'"
  else
    # dotenv 语义：只有空白之后的 # 才算注释
    quoted=${rest%%[[:space:]]##\#*}
    quoted=${quoted%%[[:space:]]##}
    unwrapped=$quoted
  fi

  # 后缀用长度切片取，避免值里的 * [ ? 被当成通配符
  reply=("$prefix" "$quoted" "${rest[$((${#quoted} + 1)),-1]}" "$unwrapped")
}

function _env_edit_write() {
  local file=$1; shift
  local tmp="$file.env_edit.$$"

  if (( $# )); then print -rl -- "$@" >| "$tmp"; else : >| "$tmp"; fi || return 1
  # 原地覆盖写而不是 mv，保留原文件的权限位
  cat -- "$tmp" >| "$file" && command rm -f -- "$tmp"
}

function env_get() {
  _env_edit_check_key "$1" || return 1
  local file=$(_env_edit_file "$2") || return 1

  local -a reply
  local line
  while IFS= read -r line || [[ -n $line ]]; do
    _env_edit_split "$line" "$1" || continue
    print -r -- "${reply[4]}"
    return 0
  done < "$file"

  _env_edit_log red "Key not found: $1 ($file)"
  return 1
}

function env_set() {
  _env_edit_check_key "$1" || return 1
  [[ -n $2 ]] || { _env_edit_log red "Usage: env_set KEY VALUE [file]"; return 1 }
  local file=$(_env_edit_file "$3") || return 1

  # 含空白 / # / 引号的值加双引号，其余保持裸值
  local text=$2
  if [[ $2 == *[[:space:]]* || $2 == *\#* || $2 == *\"* || $2 == *\'* ]]; then
    local escaped=${2//\"/\\\"}
    text="\"${escaped}\""
  fi

  local -a reply lines
  local line matched=0
  while IFS= read -r line || [[ -n $line ]]; do
    if (( !matched )) && _env_edit_split "$line" "$1"; then
      matched=1
      lines+=("${reply[1]}$1=${text}${reply[3]}")
    else
      lines+=("$line")
    fi
  done < "$file"

  if (( !matched )); then
    # 本意是改已有条目，误拼 key 时不该悄悄多出一行
    echo -n -e "\e[33m[INFO] Key '$1' not found in $file. Append it? [y/N] \e[0m" >&2
    if ! read -q; then
      echo >&2
      _env_edit_log red "Aborted: $1 not found in $file"
      return 1
    fi
    echo >&2
    lines+=("$1=${text}")
    _env_edit_log green "Appended $1 to $file"
  else
    _env_edit_log green "Updated $1 in $file"
  fi

  _env_edit_write "$file" "${lines[@]}"
}

function env_unset() {
  _env_edit_check_key "$1" || return 1
  local file=$(_env_edit_file "$2") || return 1

  local -a reply lines
  local line matched=0
  while IFS= read -r line || [[ -n $line ]]; do
    if (( !matched )) && _env_edit_split "$line" "$1"; then
      matched=1
      continue
    fi
    lines+=("$line")
  done < "$file"

  (( matched )) || { _env_edit_log red "Key not found: $1 ($file)"; return 1 }
  _env_edit_write "$file" "${lines[@]}"
  _env_edit_log green "Removed $1 from $file"
}
