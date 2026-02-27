# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# Shell Test Operators Cheatsheet (Example):
# [[ -f file ]] : True if file exists and is a regular file. (File)
# [[ -s file ]] : True if file exists and has a size greater than zero. (Size / Safe source)
# [[ -d dir  ]] : True if file exists and is a directory. (Directory)

# <<<<<<<<<<<<<<<<<<<<<< ENV Variable <<<<<<<<<<<<<<<<<<<<<<
[[ -s "$ZSH_CUSTOM/custom_env.zsh" ]] && source "$ZSH_CUSTOM/custom_env.zsh"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ PATH-START \\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

[[ -s "$HOME/.config/broot/launcher/bash/br" ]] && source "$HOME/.config/broot/launcher/bash/br"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# .cargo
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

[[ -s "${HOME}/.iterm2_shell_integration.zsh" ]] && source "${HOME}/.iterm2_shell_integration.zsh"

# bun
export BUN_INSTALL="$HOME/.bun"
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun" # bun completions
export PATH="$BUN_INSTALL/bin:$PATH"

# Added by OrbStack: command-line tools and integration
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Created by `pipx` on 2025-02-12 06:14:32
export PATH="$PATH:$HOME/.local/bin"

[[ -d "/opt/homebrew/bin" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# https://github.com/rcmdnk/homebrew-file
[[ -f $(brew --prefix)/etc/brew-wrap ]] && source $(brew --prefix)/etc/brew-wrap

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ PATH - END \\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

# git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
# ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
ZSH_THEME="spaceship"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
ZSH_THEME_RANDOM_CANDIDATES=(
  "mgutz"
  "mira"
  "jreese"
  "strug"
  "gozilla"
  "clean"
  "refined"
  "takashiyoshida"
)

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 30 # auto-update every 30 days

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="yyyy/mm/dd" # 👈 https://stackoverflow.com/a/52755693/11302760

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  git-flow
  # vscode

  # docker
  # docker-compose
  # yarn # 使用 https://github.com/antfu/ni 代替

  # git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  zsh-autosuggestions

  # git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
  fast-syntax-highlighting

  # brew install autojump
  # autojump

  # git clone https://github.com/spaceship-prompt/spaceship-react.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/spaceship-react
  spaceship-react

  # My PR has been merged and can now be used directly. (No need to customize, if you want to customize, you can refer to it.).
  # custom spaceship plugin
  # source: https://github.com/Wxh16144/dotfiles/blob/master/backup/.oh-my-zsh/custom/plugins/spaceship-commit_hash/spaceship-commit_hash.plugin.zsh, PR: https://github.com/spaceship-prompt/spaceship-prompt/pull/741
  # spaceship-commit_hash

  # custom spaceship plugin
  spaceship-git_worktree

  # https://v2ex.com/t/532304 
  # git clone https://github.com/skywind3000/z.lua ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/z.lua
  z.lua
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"



# display all paths
# https://stackoverflow.com/a/44524309/11302760
# alias paths="echo $PATH | tr \":\" \"\\n\""
function paths() {
  while read -d ':' p; do
    echo "$p"
  done <<< "$PATH:"
}
alias path=paths

autoload -Uz compinit && compinit

# load custom alias (Ensure at the end)
[[ -s "$ZSH_CUSTOM/custom_alias.zsh" ]] && source "$ZSH_CUSTOM/custom_alias.zsh"
# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
