# https://github.com/nvm-sh/nvm#manual-install
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# https://github.com/nvm-sh/nvm#deeper-shell-integration
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi

  # fix husky hook
  # ref: https://github.com/typicode/husky/issues/390#issuecomment-762213421
  # echo "export PATH=\"$(dirname $(which node)):\$PATH\"" > ~/.huskyrc # ~/.huskyrc 只适用于 husky >= v9
  # ~/.huskyrc 只适用于 husky < v9 ref: https://github.com/typicode/husky/issues/1364#issuecomment-1914199327

  # $XDG_CONFIG_HOME/husky/init.sh
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# https://github.com/nvm-sh/nvm#use-a-mirror-of-node-binaries
# https://mirrors.ustc.edu.cn/help/node.html#nvm-node-js
export NVM_NODEJS_ORG_MIRROR=https://mirrors.ustc.edu.cn/node/

# https://www.voidcanvas.com/global-module-not-found-when-node-version-is-changed-using-nvm/
function nvm_install() {
  nvm install $1 --reinstall-packages-from=default --skip-default-packages
}

# 清理 nvm 已安装的 Node.js 版本，只保留每个 major 版本的最新版本
# like: https://github.com/nvm-sh/nvm/issues/1195
function clean_nvm_versions() {
  # 适用 macos。ai 生成的
  local versions=($(nvm ls --no-colors | awk '/^ *v[0-9]+\.[0-9]+\.[0-9]+/ {gsub(/^ +/, "", $1); print $1}'))

  typeset -A latest_versions
  for v in $versions; do
    local major=$(echo $v | cut -d. -f1 | tr -d 'v')
    latest_versions[$major]=$v
  done

  local to_delete=()
  local to_keep=()
  for v in $versions; do
    local major=$(echo $v | cut -d. -f1 | tr -d 'v')
    if [[ $v != ${latest_versions[$major]} ]]; then
      to_delete+=($v)
    else
      to_keep+=($v)
    fi
  done

  # 打印所有版本
  for v in $versions; do
    local major=$(echo $v | cut -d. -f1 | tr -d 'v')
    if [[ $v != ${latest_versions[$major]} ]]; then
      print_red "$v (delete)"
    else
      print_green "$v (keep)"
    fi
  done

  if ((${#to_delete[@]} > 0)); then
    echo -n "Do you want to delete the red versions above? [y/N]: "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      for v in "${to_delete[@]}"; do
        print_yellow "Uninstalling $v ..."
        nvm uninstall $v
      done
      print_green "Done."
    else
      print_red "Aborted. No versions deleted."
    fi
  else
    print_yellow "No versions to delete."
  fi
}
