#
# Git User
#
# Show the effective Git user identity for the current repository.
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_GIT_USER_SHOW="${SPACESHIP_GIT_USER_SHOW=true}"
SPACESHIP_GIT_USER_ASYNC="${SPACESHIP_GIT_USER_ASYNC=false}"
SPACESHIP_GIT_USER_PREFIX="${SPACESHIP_GIT_USER_PREFIX="as "}"
SPACESHIP_GIT_USER_SUFFIX="${SPACESHIP_GIT_USER_SUFFIX=" "}"
SPACESHIP_GIT_USER_COLOR="${SPACESHIP_GIT_USER_COLOR="75"}"
SPACESHIP_GIT_USER_SHOW_EMAIL="${SPACESHIP_GIT_USER_SHOW_EMAIL=false}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_git_user() {
  [[ $SPACESHIP_GIT_USER_SHOW == false ]] && return

  spaceship::is_git || return

  local user_name user_email git_user

  user_name=$(command git config --get user.name 2>/dev/null)
  [[ -z "$user_name" ]] && return

  git_user="$user_name"

  if [[ $SPACESHIP_GIT_USER_SHOW_EMAIL == true ]]; then
    user_email=$(command git config --get user.email 2>/dev/null)
    [[ -n "$user_email" ]] && git_user+="<$user_email>"
  fi

  spaceship::section \
    --color "$SPACESHIP_GIT_USER_COLOR" \
    --prefix "$SPACESHIP_GIT_USER_PREFIX" \
    --suffix "$SPACESHIP_GIT_USER_SUFFIX" \
    "$git_user"
}
