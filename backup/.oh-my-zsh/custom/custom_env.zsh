export GITHUB_NAME="Wxh16144"
# export GITHUB_TOKEN="" # private

# /Users/{username} => ~
export APP=~/Library/Application\ Support
export ICLOUD=~/Library/Mobile\ Documents/com~apple~CloudDocs

# Increase Bash history size. Allow 32³ entries; the default is 1000.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";

# my projects directory
export WORKSPACE="$HOME/Code"
export COMPANY=$WORKSPACE/company
export OSS=$WORKSPACE/oss
export MY=$WORKSPACE/self
export PLAY=$WORKSPACE/playground

# registry
export COMPANY_NPM_REGISTRY="https://packages.aliyun.com/616ff38165b9775dd591fcc9/npm/npm-registry/"
export MY_NPM_REGISTRY="http://nas.wxhboy.cn:98/"
# export COMPANY_DOCKER_REGISTRY="https://example.com"

# git backup
export BACKUP_REMOTE_NAME="backup"

# Fixing "The chromium binary is not available for arm64"
# see: https://www.broddin.be/fixing-the-chromium-binary-is-not-available-for-arm64/
# node -e 'console.log(process.arch)' // arm64
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=`which chromium`
