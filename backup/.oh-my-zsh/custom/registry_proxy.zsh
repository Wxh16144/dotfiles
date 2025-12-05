# ==================================================================
# ========================= Rust CHINA =============================
# ==================================================================

# https://rsproxy.cn/
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

# ==================================================================
# ======================== NPM BINARY CHINA ========================
# ==================================================================

# https://github.com/cnpm/binary-mirror-config/blob/master/package.json#L53
export COREPACK_NPM_REGISTRY="https://registry.npmmirror.com"
export NODEJS_ORG_MIRROR="https://cdn.npmmirror.com/binaries/node"
# export NVM_NODEJS_ORG_MIRROR="https://cdn.npmmirror.com/binaries/node"
export PHANTOMJS_CDNURL="https://cdn.npmmirror.com/binaries/phantomjs"
export CHROMEDRIVER_CDNURL="https://cdn.npmmirror.com/binaries/chromedriver"
export OPERADRIVER_CDNURL="https://cdn.npmmirror.com/binaries/operadriver"
export ELECTRON_MIRROR="https://cdn.npmmirror.com/binaries/electron/"
export ELECTRON_BUILDER_BINARIES_MIRROR="https://cdn.npmmirror.com/binaries/electron-builder-binaries/"
export PLAYWRIGHT_DOWNLOAD_HOST="https://cdn.npmmirror.com/binaries/playwright"
export SASS_BINARY_SITE="https://cdn.npmmirror.com/binaries/node-sass"
export SWC_BINARY_SITE="https://cdn.npmmirror.com/binaries/node-swc"
export NWJS_URLBASE="https://cdn.npmmirror.com/binaries/nwjs/v"
export SENTRYCLI_CDNURL="https://cdn.npmmirror.com/binaries/sentry-cli"
export SAUCECTL_INSTALL_BINARY_MIRROR="https://cdn.npmmirror.com/binaries/saucectl"
export npm_config_sharp_binary_host="https://cdn.npmmirror.com/binaries/sharp"
export npm_config_sharp_libvips_binary_host="https://cdn.npmmirror.com/binaries/sharp-libvips"
export npm_config_robotjs_binary_host="https://cdn.npmmirror.com/binaries/robotj"
# For Cypress >=10.6.0, https://docs.cypress.io/guides/references/changelog#10-6-0
export CYPRESS_DOWNLOAD_PATH_TEMPLATE='https://cdn.npmmirror.com/binaries/cypress/${version}/${platform}-${arch}/cypress.zip'

# https://zhuanlan.zhihu.com/p/637107614
# puppeteer<=19
export PUPPETEER_DOWNLOAD_HOST="https://cdn.npmmirror.com/binaries"
# puppeteer>20.1+
export PUPPETEER_DOWNLOAD_BASE_URL="https://cdn.npmmirror.com/binaries/chrome-for-testing"

# https://midwayjs.org/docs/hooks/prisma
# https://www.prisma.io/docs/orm/reference/environment-variables-reference#downloading-engines
export PRISMA_ENGINES_MIRROR="https://cdn.npmmirror.com/binaries/prisma"

# https://github.com/cnpm/cnpmcore/issues/594#issuecomment-2105511083
export EDGEDRIVER_CDNURL="https://npmmirror.com/mirrors/edgedriver"

# Fixing "The chromium binary is not available for arm64"
# see: https://www.broddin.be/fixing-the-chromium-binary-is-not-available-for-arm64/
# Chromium 已损坏，无法打开? `brew install chromium --no-quarantine` 或 `xattr -cr /Applications/Chromium.app`
# node -e 'console.log(process.arch)' // arm64
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=`which chromium`

# ==================================================================
# ====================== HomeBrew MIRROR ===========================
# ==================================================================

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
