#!/bin/bash
# Ugly Avatar CLI Helper
#
# Source: https://github.com/Wxh16144/ugly-avatar-server
#
# Usage:
#   source ugly-avatar.plugin.zsh
#
#   ugly [id] [size] [format] [bg]
#
# Examples:
#   ugly
#   ugly my-id
#   ugly my-id 256 svg

export UGLY_AVATAR_URL="http://avatar.test/"

ugly() {
  # Configuration: Use UGLY_AVATAR_URL env var if set, otherwise default to localhost
  local endpoint="${UGLY_AVATAR_URL:-http://localhost:3000}"
  
  # Arguments: ugly [id] [size] [format] [bg]
  # You can also set default background via UGLY_AVATAR_BG env var (e.g., "transparent" or a hex color)
  local id=${1:-$(openssl rand -hex 4)}
  local size=${2:-512}
  local format=${3:-png}
  local bg=${4:-${UGLY_AVATAR_BG:-}}
  
  local file="${id}.${format}"
  local url="${endpoint}/${file}?s=${size}"
  if [ -n "$bg" ]; then
    url="${url}&bg=${bg}"
  fi
  
  # Show repo/source info and download
  echo "Downloading $url..."
  curl -sL "$url" -o "$file"
  echo "Saved to $file"
}