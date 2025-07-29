# 镜像助手 https://brew.idayer.com/guide/change-source

# 中科大
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/bottles"

# node-canvas、node-gyp
# ref: https://github.com/Automattic/node-canvas?tab=readme-ov-file#compiling
# brew install pkg-config cairo pango libpng jpeg giflib librsvg pixman

# https://stackoverflow.com/a/58449841
export HOMEBREW_NO_AUTO_UPDATE=true
