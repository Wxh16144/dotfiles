# 一些临时的快捷方式

# 公司产品原型
export COM_AXURE=$COMPANY/axure 
# export COM_ARTIFACTS=$COMPANY/artifacts
export COM_ARTIFACTS=$TMPDIR/$(whoami)-COMPANY/artifacts

# 递归删除目录下的 .DS_Store 文件
function __internal_remove__ds_store() {
  if [[ $PWD != $COMPANY* ]]; then
    echo "You are not in the company directory"
    return 1
  fi

  find . -name ".DS_Store" -exec /bin/rm -f {} \;
}
alias rmds="__internal_remove__ds_store"
function __internal_ensure__com_dir() {
  local dirs=(
    $COM_AXURE
    $COM_ARTIFACTS
  )

  for dir in ${dirs[@]}; do
    if [ ! -d $dir ]; then
      mkdir -p $dir
    fi
  done
}
__internal_ensure__com_dir


# 下载公司构建产物
function com_download() {
  local url=$1
  local target=$COM_ARTIFACTS
  if [ -n "$2" ]; then
    target=$2
  fi

  if [ -z "$url" ]; then
    echo "Usage: com_download <url> [target]"
    return 1
  fi

  cd $target
  curl -O $url
  # back to original directory
  cd -
}

alias com0="http-server $COM_AXURE -p 10086 -c-1 -o"
alias como="open $COM_ARTIFACTS"

# Savery 编辑器
alias com1="cd $COMPANY/savery-editor" 
alias com1c="cd $COMPANY/saveryconfig" # 配置项

# 哥伦布编辑器
alias com2="cd $COMPANY/columbus-editor" 
alias com2c="cd $COMPANY/columbus-config" # 配置项

# SE 编辑器
alias com5="cd $COMPANY/editor-se"
# 基础库
alias comcore="cd $COMPANY/common-editor"

# 基础库的 package 太复杂了，拆开
alias csd="npx turbo dev --no-cache --continue --filter=\"./packages/components*\" --filter=\"./packages/core\""
alias csb="npx turbo build --no-cache --continue --filter=\"./packages/components*\" --filter=\"./packages/core\""

