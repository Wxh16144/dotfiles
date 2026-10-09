#!/bin/bash

# crontab 的 PATH 极简，补上 Homebrew / 本地 bin（jq 等）
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH

HOME_DIR="${HOME:-"/"}"
CONFIG_DIR="${CONFIG:-"$HOME_DIR/.config"}"

# path 中的 {VARIABLE} 取同名环境变量（crontab 下没有 zsh 变量，需要时在此自行补充）
COMPANY="${COMPANY:-"$HOME_DIR/Code/company"}"
OSS="${OSS:-"$HOME_DIR/Code/oss"}"

# 外部配置文件：依次在 $AUTO_UPDATE_REPOS_CONF、$CONFIG、$HOME 下按此文件名查找
CONF_NAME="keep-project-fresh.conf.jsonc"

# 默认仓库列表；外部 JSON 配置的 repos 会追加到本列表（追加，非覆盖）
# 配置：定义仓库路径，格式为 "路径|分支|后置命令"
# - 分支：可选。指定要拉取的分支，如 "main" 或 "develop"。留空则使用当前检出的分支。
# - 后置命令：可选。pull 成功后执行的命令。
#
# 示例：
# "path/to/repo|main|npm install"  -> 强制 main 分支，执行 npm install
# "path/to/repo||npm install"      -> 跟随当前分支，执行 npm install
# "path/to/repo|develop"           -> 强制 develop 分支，无后置命令
# "path/to/repo"                   -> 最简配置：跟随当前分支，无命令

repos=(
    # "$OSS/WeFlow|main"
    "$OSS/ChatLab|main"
    "$OSS/lobehub/lobe-ui|master"
    "$OSS/lobehub/lobe-chat|canary"
    "$OSS/ant-design/antd_6x|master"
)

# 可选：定义全局默认分支（仅当配置中分支字段为空，且这里设置了值时生效。留空则默认各自的当前分支）
# 外部配置的 defaultBranch 非空时会覆盖此值
default_global_branch=""

# --- 外部配置 ---------------------------------------------------------------
# 可选 JSONC 配置，字段示例：
#   {
#     "defaultBranch": "main",
#     "repos": [
#       {
#         "path": "{COMPANY}/foo",
#         "branch": "main",
#         "afterscript": "pnpm install"
#       }
#     ]
#   }
# - repos 追加在脚本内列表之后（非覆盖）；path 必填且支持 {VARIABLE}
# - branch 缺省跟随当前分支；afterscript 仅在 pull 有更新后执行
# - 依赖 jq，未安装或解析失败则跳过本配置

# 去掉 jsonc 的行内 //、整行 //、/* */ 注释（jq 不认注释）；字符串内的 // 不受影响
strip_jsonc() {
    awk '
        BEGIN { in_block = 0; in_str = 0 }
        {
            out = ""; i = 1; n = length($0)
            while (i <= n) {
                c = substr($0, i, 1)
                if (in_block) {
                    if (c == "*" && substr($0, i + 1, 1) == "/") { in_block = 0; i += 2 } else { i++ }
                    continue
                }
                if (in_str) {
                    out = out c
                    if (c == "\\") { out = out substr($0, i + 1, 1); i += 2; continue }
                    if (c == "\"") in_str = 0
                    i++; continue
                }
                if (c == "\"") { in_str = 1; out = out c; i++; continue }
                if (c == "/" && substr($0, i + 1, 1) == "/") break
                if (c == "/" && substr($0, i + 1, 1) == "*") { in_block = 1; i += 2; continue }
                out = out c; i++
            }
            print out
        }
    '
}

# 将 {VAR}（仅全大写）替换为变量值；未定义的变量原样保留并告警
expand_vars() {
    local rest="$1" out="" pre value
    while [[ "$rest" =~ \{([A-Z_][A-Z0-9_]*)\} ]]; do
        local match="${BASH_REMATCH[0]}"
        local name="${BASH_REMATCH[1]}"
        pre="${rest%%"$match"*}"
        out="${out}${pre}"
        rest="${rest#*"$match"}"
        value="${!name}"
        if [[ -n "$value" ]]; then
            out="${out}${value}"
        else
            echo "⚠️  未定义变量 ${match}，按原样使用" >&2
            out="${out}${match}"
        fi
    done
    printf '%s' "${out}${rest}"
}

# 查找顺序：$AUTO_UPDATE_REPOS_CONF > $CONFIG/$CONF_NAME > $HOME/$CONF_NAME
conf_file=""
for candidate in \
    "$AUTO_UPDATE_REPOS_CONF" \
    "$CONFIG_DIR/$CONF_NAME" \
    "$HOME_DIR/$CONF_NAME"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then
        conf_file="$candidate"
        break
    fi
done

US=$'\x1f'          # 字段分隔符（非空白字符，避免空字段被合并）
extra_repos=()      # 外部追加的仓库，每项为 "path<US>branch<US>afterscript"

if [[ -n "$conf_file" ]]; then
    jq_bin=""
    for candidate in jq /opt/homebrew/bin/jq /usr/local/bin/jq; do
        if jq_bin=$(command -v "$candidate" 2>/dev/null); then
            break
        fi
        jq_bin=""
    done

    if [[ -z "$jq_bin" ]]; then
        echo "⚠️  未找到 jq，跳过配置文件: $conf_file" >&2
    else
        conf_json=$(strip_jsonc <"$conf_file")
        conf_lines=$("$jq_bin" -r '
            (.repos // [])
            | map(select(type == "object" and ((.path? // "") != "")))
            | .[]
            | [(.path), (.branch // ""), (.afterscript // "")]
            | join("\u001f")
        ' <<<"$conf_json" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "⚠️  配置解析失败，跳过: $conf_file" >&2
        else
            while IFS= read -r line; do
                [[ -n "$line" ]] && extra_repos+=("$line")
            done <<<"$conf_lines"

            conf_default_branch=$("$jq_bin" -r '.defaultBranch // empty' <<<"$conf_json" 2>/dev/null)
            if [[ -n "$conf_default_branch" ]]; then
                default_global_branch="$conf_default_branch"
            fi

            echo "📄 已加载配置: $conf_file (+${#extra_repos[@]} 个仓库)"
        fi
    fi
fi

# 合并：默认列表（转 <US> 分隔）+ 外部追加
all_repos=()
for item in "${repos[@]}"; do
    IFS='|' read -r -a config <<<"$item"
    all_repos+=("$(printf '%s%s%s%s%s' "${config[0]}" "$US" "${config[1]}" "$US" "${config[2]}")")
done
all_repos+=("${extra_repos[@]}")

# --- 开始处理所有仓库 ------------------------------

echo "---------------------------- $(date +'%Y-%m-%d %H:%M:%S') ----------------------------"

current_date=$(date +%Y-%m-%d-%H_%M_%S)
result=""

for item in "${all_repos[@]}"; do
    # 解析配置项（path、branch、afterscript）
    IFS="$US" read -r repo_path target_repo_branch afterscript <<<"$item"

    # {VARIABLE} 变量替换
    repo_path=$(expand_vars "$repo_path")
    target_repo_branch=$(expand_vars "$target_repo_branch")
    afterscript=$(expand_vars "$afterscript")

    # 检查目录是否存在
    if [ ! -d "$repo_path" ]; then
        echo "🚫 目录未找到: $repo_path"
        result="$result\n🚫 $(basename "$repo_path") (未找到)"
        continue
    fi

    # 检查是否为 git 仓库
    if [ -d "$repo_path/.git" ]; then
        echo
        echo "🚀 正在处理: $repo_path"

        # 进入目录
        cd "$repo_path" || {
            echo "❌ 无法进入目录: $repo_path"
            result="$result\n❌ $(basename "$repo_path") (拒绝访问)"
            continue
        }

        short_dir="$(basename "$(dirname "$repo_path")")/$(basename "$repo_path")"
        current_branch=$(git rev-parse --abbrev-ref HEAD)

        # 1. 先检查当前状态，如果有未提交更改，先 stash 起来，避免切换分支失败
        if [[ -n $(git status --porcelain) ]]; then
            echo "📦 当前目录不干净 ($current_branch)，正在暂存 (Stash) 更改(含新建文件)..."
            git stash push -u -m "auto_stash_$current_date"
        fi

        # 2. 确定要拉取的最终目标分支
        # 优先级：单项配置 > 全局默认
        final_target_branch=""
        if [[ -n "$target_repo_branch" ]]; then
            final_target_branch="$target_repo_branch"
        elif [[ -n "$default_global_branch" ]]; then
            final_target_branch="$default_global_branch"
        fi

        # 3. 如果指定了目标分支且与当前不一致，则切换
        if [[ -n "$final_target_branch" && "$current_branch" != "$final_target_branch" ]]; then
            echo "⚠️  检测到当前分支 ($current_branch) 与目标 ($final_target_branch) 不一致，正在切换..."
            git checkout "$final_target_branch"
            if [[ $? -ne 0 ]]; then
                echo "❌ 切换到 $final_target_branch 失败，跳过..."
                result="$result\n❌ $short_dir (切换失败)"
                continue
            fi
            # 更新当前分支变量
            current_branch="$final_target_branch"
        fi

        # 优先选择 upstream 作为拉取目标，如果没有则使用 origin
        target_remote="origin"
        if git remote | grep -q "^upstream$"; then
            target_remote="upstream"
        fi

        echo "⬇️  正在拉取 $target_remote $current_branch..."
        head_before=$(git rev-parse --short HEAD)
        pull_output=$(git pull "$target_remote" "$current_branch" 2>&1)
        pull_exit_code=$?

        # Output the pull result to console so user can see details if running manually
        echo "$pull_output"

        if [ $pull_exit_code -eq 0 ]; then
            status_icon="✅"
            extra_msg=""
            current_hash=$(git rev-parse --short HEAD)

            # 以 HEAD 是否变化判断有无更新，避免依赖 git 输出的本地化文案
            status_no_change=""
            has_updates=false
            if [[ "$current_hash" == "$head_before" ]]; then
                status_no_change=" (无变动)"
            else
                status_no_change=" 🆙"
                has_updates=true
            fi

            # 如果存在、拉取成功且有代码变更，则执行后置命令
            if [[ -n "$afterscript" ]]; then
                if [[ "$has_updates" == "true" ]]; then
                    echo "⚙️  检测到代码更新，执行后置命令: $afterscript"
                    if eval "$afterscript"; then
                        extra_msg=" + 命令成功"
                    else
                        status_icon="⚠️ "
                        extra_msg=" + 命令失败"
                        echo "❌ 后置命令失败。"
                    fi
                else
                    echo "💤 无代码变更，跳过后置命令。"
                fi
            fi

            result="${result}\n${status_icon} ${short_dir} (${current_branch}@${current_hash})${status_no_change}${extra_msg}"
        else
            echo "❌ 拉取目录 $repo_path 失败"
            result="${result}\n❌ ${short_dir} (拉取失败)"
        fi
        echo
    else
        echo "🚫 $repo_path 不是有效的 git 仓库。"
        result="${result}\n🚫 $(basename "$repo_path") (非 git 仓库)"
    fi
done

echo
echo "============================================================"
echo -e "📊 执行汇总报告: $(date +'%Y-%m-%d %H:%M:%S') $result"
echo "============================================================"
echo
