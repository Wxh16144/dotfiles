#!/bin/bash

mask_sensitive_values() {
  local line="$1"

  if [[ $line =~ ^export ]]; then
    local var_name=$(echo "$line" | awk -F'[ =]+' '{print $2}')
    local var_value=$(echo "$line" | awk -F'[ =]+' '{print $3}')

    if [[ $var_value == *{* ]]; then
      echo "$line"
    else
      local masked_part=${MARK:-"xxxxxxxx"}
      local preserved_part=""

      local delim_pos="${var_value#*[-_]}"
      if [[ ${var_value:0:${#delim_pos}} != $var_value ]]; then
        local preserved_part="${var_value:0:${#var_value}-${#delim_pos}}"
      fi

      local masked_value="${preserved_part}${masked_part}"

      echo "export ${var_name}=${masked_value}"
    fi
  else
    echo "$line"
  fi
}

# 环境变量脱敏
# e.g: desensitize_env $ZSH_CUSTOM/private_env.zsh [$ZSH_CUSTOM/private_env.desensitized.zsh]
desensitize_env() {
  local env_file="$1"
  local desensitized_env_file="${2:-/dev/stdout}"

  while IFS= read -r line; do
    mask_sensitive_values "$line" >"$desensitized_env_file"
  done <"$env_file"
}
