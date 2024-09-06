#!/usr/bin/env bash

# 参考：https://github.com/mathiasbynens/dotfiles/blob/main/bootstrap.sh
# 仅给 GitHub codespaces 使用，你应该不会使用到这个文件
# 用于初始化 codespaces 环境：https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account#dotfiles

# 检查并且断言 nodejs 版本（v18+
function assert_node_version() {
  local node_version=$(node -v)
  local major_version=$(echo $node_version | cut -d. -f1 | sed 's/v//g')
  if [ $major_version -lt 18 ]; then
    echo "Node.js version is too low, please upgrade to v18+"
    exit 1
  fi
}

function main() {
  cd "$(dirname "${BASH_SOURCE}")";

  git pull origin master;

  assert_node_version;

  # install dependencies
  npm install;

  # restore
  npm run fuck;
}

main;
