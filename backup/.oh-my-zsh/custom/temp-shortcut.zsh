# 一些临时的快捷方式


# GitHub 组织 https://github.com/lobehub

autoload -U add-zsh-hook

# 写的比较粗糙，可以自己决定逻辑
lobehub__detect_expected_project() {
  local project_name=${1:-"lobehub-monorepo"}

  if [[ $(basename "$PWD") != "$project_name" ]]; then
    return 1
  fi

  if [[ $(git remote -v | grep "$project_name") == "" ]]; then
    return 1
  fi

  return 0
}

# 将 lobehub-monorepo 总是保持最新状态
lobehub__always_latest() {
  if lobehub__detect_expected_project && [[ $(git status -s) == "" ]]; then
    echo "Auto Updating lobehub-monorepo..."
    git pull --recurse-submodules
  fi
}

add-zsh-hook chpwd lobehub__always_latest
lobehub__always_latest

# 公司产品原型
export COM_AXURE=$COMPANY/axure 
