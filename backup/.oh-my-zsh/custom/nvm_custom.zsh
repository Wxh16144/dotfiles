# https://github.com/nvm-sh/nvm#manual-install
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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
  # echo "export PATH=\"$(dirname $(which node)):\$PATH\"" > ~/.huskyrc 
  # 上面这个只适用于 husky < v9 ref: https://github.com/typicode/husky/issues/1364#issuecomment-1914199327
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
