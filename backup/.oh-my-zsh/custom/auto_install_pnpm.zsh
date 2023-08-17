# 起源
# 经常维护几个开源项目，其 pnpm 版本都不一样。经常使用 npm i -g pnpm@x.x.x 比较麻烦。
# 进入一个目录时判断是否有 package.json，如果有，判断是否有 packageManager，如果有，判断是否是 pnpm
# 如果是 pnpm，检查本地 pnpm 版本是否和 packageManager 中的版本一致，如果不一致，自动安装

# 前置依赖！！！
# 安装了 jq: https://jqlang.github.io/jq/ 用于解析 json
# 安装了 Node.js: https://nodejs.org/en/ 用于执行 npm 命令

autoload -Uz add-zsh-hook
auto-install-pnpm() {
  # 加入 jq 和 npm 命令是否存在的判断
  if ! command -v jq &> /dev/null; then
    echo "jq command not found. Please install jq first."
    return
  fi

  if ! command -v npm &> /dev/null; then
    echo "npm command not found. Please install npm first."
    return
  fi

  # 判断当前目录是否有 package.json 和 packageManager 字段
  if [[ -f package.json ]]; then
    local package_manager=$(cat package.json | jq -r '.packageManager')
    if [[ $package_manager == "pnpm"* ]]; then
      # 判断本地 pnpm 版本是否和 packageManager 中的版本一致
      local expected_pnpm_version=$(echo $package_manager | cut -d "@" -f 2)
      local local_current_pnpm_version=$(pnpm --version)

      # 如果本地 pnpm 版本和 packageManager 中的版本不一致，自动安装
      if [[ $local_current_pnpm_version != $expected_pnpm_version ]]; then
        echo "Local pnpm version ($local_current_pnpm_version) does not match expected version ($expected_pnpm_version). Installing npm packages..."
        npm install pnpm@$expected_pnpm_version --global --registry=https://registry.npmmirror.com/
        echo "pnpm@$expected_pnpm_version installed successfully."
      else
        echo "Local pnpm version is up to date."
      fi
    fi
  fi
}

add-zsh-hook chpwd auto-install-pnpm
auto-install-pnpm
