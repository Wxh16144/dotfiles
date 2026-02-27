# ref: https://stackoverflow.com/questions/38475154/set-title-and-badge-text-in-iterm
# ref: https://iterm2.com/documentation-shell-integration.html
# ref: https://iterm2.com/3.0/documentation-badges.html

# This will set your window title
export PROMPT_COMMAND='echo -sne "\033]0;${PWD##*/}\007"'
# source ~/.iterm2_shell_integration.`basename $SHELL`

# This creates the var currentDir to use later on
function iterm2_print_user_vars() {
  iterm2_set_user_var currentDir "${PWD##*/}"

  local badge_icon="📂"
  
  # Ensure the map is defined
  if (( ${#DIRECTORY_BADGES} )); then
    # Find matching path
    for dir_path in "${(@k)DIRECTORY_BADGES}"; do
      if [[ "$PWD" == "$dir_path"* ]]; then
        badge_icon="${DIRECTORY_BADGES[$dir_path]}"
        break
      fi
    done
  fi

  iterm2_set_user_var badge "$badge_icon ${PWD##*/}"
}
