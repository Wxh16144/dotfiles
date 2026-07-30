# 控制变量约定: ENABLE_<GROUP_NAME>=1 则启用该组环境变量

function __register_env_group() {
  local name="${1:u}"
  shift
  typeset -ga "__ENV_GROUP_${name}"
  set -A "__ENV_GROUP_${name}" "$@"
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

# ==================================================================
# ======================= ENV GROUP PRESETS =========================
# ==================================================================

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
