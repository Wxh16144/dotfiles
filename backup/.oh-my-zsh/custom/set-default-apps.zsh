#!/usr/bin/env zsh
# macOS 批量设置默认打开方式（变量复用+无报错版）

set-default-apps() {
  # 🔶 1. 定义应用变量
  local TEXT_EDITOR="com.apple.TextEdit"
  local VSCODE="com.microsoft.VSCode,$TEXT_EDITOR"
  local ZED="dev.zed.Zed,$VSCODE"
  local BROWSER="com.google.Chrome,com.apple.Safari"
  local PREVIEW="com.apple.Preview"
  local OBSIDIAN="abnerworks.obsidian,$ZED"

  # 🔶 2. 检查依赖
  (( $+commands[duti] )) || { echo "❌ 请先安装: brew install duti"; return 1; }

  # 🔶 3. 核心配置
  local config=(
    ".js|.ts|.tsx|.jsx=$VSCODE"
    ".py|.json|.jsonc|.json5|.yaml|.yml|.log|.txt=$ZED"
    ".md=$OBSIDIAN"
    ".png|.jpg=$PREVIEW"
    ".pdf|.html|.htm=$BROWSER"
  )

  # 🔶 通用的 App 存在性检查函数
  app_exists() {
    local bundle_id="$1"
    # 优先用 lsappinfo（macOS 原生工具）检查，无兼容问题
    if lsappinfo info -only bundleid "$bundle_id" &>/dev/null; then
      return 0
    fi
    # 兜底：检查 App 文件是否存在
    local app_path
    app_path=$(mdfind "kMDItemCFBundleIdentifier == '$bundle_id'" -limit 1)
    [[ -n "$app_path" && -d "$app_path" ]] && return 0
    return 1
  }

  echo "🚀 开始设置默认应用..."
  local line exts apps ext app
  for line in $config; do
    # 拆分 后缀组 和 应用列表
    IFS='=' read -r exts apps <<< "$line"
    
    # 遍历每个后缀
    for ext in ${(s:|:)exts}; do
      local found=false
      # 遍历备选应用，找第一个安装的
      for app in ${(s:,:)apps}; do
        if app_exists "$app"; then
          duti -s "$app" "$ext" all
          echo "✅ $ext → $app"
          found=true
          break
        fi
      done
      [[ "$found" == false ]] && echo "⚠️ $ext: 无可用应用"
    done
  done

  killall Finder 2>/dev/null
  echo "\n🎉 全部设置完成！"
}
