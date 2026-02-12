# https://codepoints.net/U+1D47E
local MAGIC_CAPITAL_W='\U0001D47E'

# https://codepoints.net/U+1D496
local MAGIC_SMALL_U='\U0001D496'

# https://codepoints.net/U+1D499
local MAGIC_SMALL_X='\U0001D499'

# https://codepoints.net/U+1D489
local MAGIC_SMALL_H='\U0001D489'

# https://codepoints.net/U+1D7F7
local MAGIC_NUMBER_ONE='\U0001D7F7'

# https://codepoints.net/U+1D7FA
local MAGIC_NUMBER_FOUR='\U0001D7FA'

# https://codepoints.net/U+1D7FC
local MAGIC_NUMBER_SIX='\U0001D7FC'

local _MAGIC_ID=(
  $MAGIC_CAPITAL_W
  $MAGIC_SMALL_X
  $MAGIC_SMALL_H
  $MAGIC_NUMBER_ONE
  $MAGIC_NUMBER_SIX
  $MAGIC_NUMBER_ONE
  $MAGIC_NUMBER_FOUR
  $MAGIC_NUMBER_FOUR
)

local _MAGIC_NAME=(
  $MAGIC_CAPITAL_W
  $MAGIC_SMALL_U
  $MAGIC_SMALL_X
  $MAGIC_SMALL_H
)

export MAGIC_ID=$(printf "%s" "${_MAGIC_ID[@]}")
export MAGIC_NAME=$(printf "%s" "${_MAGIC_NAME[@]}")

# ==================================================================
# =========== Zero-width character combination generator ===========
# ==================================================================

# see: https://github.com/Wxh16144/wxh16144.github.io/blob/main/source/notes/index.md#zwsp
# 零宽字符定义
ZW_CHARS=($'\u200b' $'\u200c' $'\u200d' $'\u200e' $'\u200f' $'\ufeff')

# 递归生成
_generate_perms() {
    local prefix=$1; shift
    [[ -z "$ZSH_VERSION" ]] && local IFS=' ' # 仅 Bash 需要显式处理
    [ -n "$prefix" ] && echo "$prefix"
    
    local i; for i in "$@"; do
        local head=$1; shift
        _generate_perms "$prefix$head" "$@"
        set -- "$@" "$head" # 将当前元素移到末尾，实现数组轮转
    done
}

# 生成字典并用换行符存储
export ZW_DICT="$(_generate_perms "" "${ZW_CHARS[@]}")"

# 将索引转换为零宽字符组合
_idx_to_zw() {
    local val=$1
    local total=$(echo "$ZW_DICT" | wc -l)
    local result=""
    
    # 采用类进制转换逻辑，确保大索引也能被完整编码
    while true; do
        local remainder=$(( val % total ))
        local char=$(echo "$ZW_DICT" | sed -n "$((remainder + 1))p")
        result="$char$result"
        val=$(( val / total ))
        [ "$val" -le 0 ] && break
    done
    echo -n "$result"
}

get_zw() {
    local idx=$1
    local safe_mode=${2:-0}
    
    # Zsh 兼容的数组转换方式
    # 将换行符分隔的 ZW_DICT 转换为数组 ZW_ARRAY
    local -a ZW_ARRAY
    ZW_ARRAY=(${(f)ZW_DICT})
    
    local total=${#ZW_ARRAY[@]}
    
    # 防御性编程：检查字典是否加载成功
    if [[ $total -eq 0 ]]; then
        echo "Error: ZW_DICT is empty." >&2
        return 1
    fi
    
    local result=""
    [[ $idx -lt 0 ]] && idx=$((-idx))

    # 进制转换逻辑
    while true; do
        # Zsh 数组索引从 1 开始
        local remainder=$(( idx % total ))
        local char="${ZW_ARRAY[$((remainder + 1))]}"
        
        if [[ "$safe_mode" == "1" ]]; then
            if [[ -z "$result" ]]; then
                result="$char"
            else
                result="$char/$result"
            fi
        else
            result="$char$result"
        fi
        
        idx=$(( idx / total ))
        [[ $idx -le 0 ]] && break
    done
    
    echo -n "$result"
}

# 快捷调用
get_zw_by_idx() { get_zw "$1"; }
get_safe_zw_by_idx() { get_zw "$1" 1; }
