# Docker pull acceleration
# Usage: dpull <image_name>
# Example: dpull nginx:latest

local RED="\033[31;1m"
local GREEN="\033[32;1m"
local YELLOW="\033[33;1m"
local RESET="\033[0m"

# 配置文件路径
local DOCKER_MIRROR_CONFIG="$TMPDIR/docker_mirror_config"

print_red() {
  echo -e "${RED}$*${RESET}"
}
print_green() {
  echo -e "${GREEN}$*${RESET}"
}
print_yellow() {
  echo -e "${YELLOW}$*${RESET}"
}

# 管理 docker 镜像源
# usage: docker_mirror_manage [mirror_name]
function docker_mirror_manage() {
  local input_mirror=$1
  
  # 预设的 mirrors
  declare -A mirrors
  mirrors=(
    # https://1ms.run/
    [1ms]="docker.1ms.run"
    # https://docker.xuanyuan.me/
    [xuanyuan]="docker.xuanyuan.me"
  )

  # 如果没有参数, 则表示查看当前 mirror
  if [ $# -eq 0 ]; then
    if [[ -f $DOCKER_MIRROR_CONFIG ]]; then
        local current_mirror=$(cat $DOCKER_MIRROR_CONFIG)
        print_green "Current mirror: $current_mirror"
    else 
        print_yellow "No mirror selected."
    fi

    print_green "Available mirrors:"
    for key in ${(@k)mirrors}; do
      echo -e " ${RED}$key: ${YELLOW}${mirrors[$key]}${RESET}";
    done
    return
  fi

  # 判断输入的 mirror 是否存在于预设中
  local selected_mirror=""
  if [[ -n ${mirrors[$input_mirror]} ]]; then
    selected_mirror=${mirrors[$input_mirror]}
  else
    # 允许直接输入 域名
    selected_mirror=$input_mirror
  fi

  echo $selected_mirror > $DOCKER_MIRROR_CONFIG
  print_green "Set docker mirror to: $selected_mirror"
}

alias dmm='docker_mirror_manage'

function dpull() {
  local image=$1
  
  if [[ -z $image ]]; then
    print_red "Please provide an image name."
    return 1
  fi
  
  # 从配置文件读取 mirror
  if [[ ! -f $DOCKER_MIRROR_CONFIG ]]; then
    print_red "No docker mirror configured. Please run 'docker_mirror_manage [mirror]' first."
    return 1
  fi
  
  local mirror=$(cat $DOCKER_MIRROR_CONFIG)
  if [[ -z $mirror ]]; then
    print_red "Docker mirror configuration is empty. Please run 'docker_mirror_manage [mirror]' again."
    return 1
  fi

  local accelerated_image="$mirror/$image"

  print_yellow "Pulling $accelerated_image..."
  docker pull $accelerated_image

  if [[ $? -eq 0 ]]; then
    print_green "Pull success. Retagging to $image..."
    docker tag $accelerated_image $image
    
    print_yellow "Removing temporary tag $accelerated_image..."
    docker rmi $accelerated_image
    
    print_green "Done! Image $image is ready."
  else
    print_red "Failed to pull image."
    return 1
  fi
}
