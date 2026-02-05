#
# Git Worktree
#
# Check if the current directory is inside a worktree.
# If there are multiple worktrees, distinguish between the main worktree and linked worktrees.
#

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

SPACESHIP_GIT_WORKTREE_SHOW="${SPACESHIP_GIT_WORKTREE_SHOW=true}"
SPACESHIP_GIT_WORKTREE_ASYNC="${SPACESHIP_GIT_WORKTREE_ASYNC=false}"
SPACESHIP_GIT_WORKTREE_PREFIX="${SPACESHIP_GIT_WORKTREE_PREFIX=""}"
SPACESHIP_GIT_WORKTREE_SUFFIX="${SPACESHIP_GIT_WORKTREE_SUFFIX=""}"
SPACESHIP_GIT_WORKTREE_COLOR="${SPACESHIP_GIT_WORKTREE_COLOR="cyan"}"
SPACESHIP_GIT_WORKTREE_SYMBOL_MAIN="${SPACESHIP_GIT_WORKTREE_SYMBOL_MAIN="[🏗️root]"}"
SPACESHIP_GIT_WORKTREE_SYMBOL_LINKED="${SPACESHIP_GIT_WORKTREE_SYMBOL_LINKED="[🌿worktree]"}"
SPACESHIP_GIT_WORKTREE_SYMBOL_DETACHED="${SPACESHIP_GIT_WORKTREE_SYMBOL_DETACHED="[⚓worktree]"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------

spaceship_git_worktree() {
  [[ $SPACESHIP_GIT_WORKTREE_SHOW == false ]] && return

  spaceship::is_git || return

  # Check if there are multiple worktrees
  # git worktree list always returns at least one line (the main worktree)
  local worktree_count
  worktree_count=$(command git worktree list 2>/dev/null | wc -l)

  # If there's only one worktree (the main repo itself without additional worktrees), return
  [[ $worktree_count -le 1 ]] && return

  local worktree_symbol toplevel

  toplevel=$(command git rev-parse --show-toplevel 2>/dev/null)

  # Determine if Main or Linked worktree
  # Main worktree has .git as directory. Linked has .git as file.
  if [[ -d "$toplevel/.git" ]]; then
    worktree_symbol="$SPACESHIP_GIT_WORKTREE_SYMBOL_MAIN"
  else
    # Linked worktrees can be either detached or linked 
    if ! command git symbolic-ref -q HEAD &>/dev/null; then
      worktree_symbol="$SPACESHIP_GIT_WORKTREE_SYMBOL_DETACHED"
    else
      worktree_symbol="$SPACESHIP_GIT_WORKTREE_SYMBOL_LINKED"
    fi
  fi

  spaceship::section \
    --color "$SPACESHIP_GIT_WORKTREE_COLOR" \
    --prefix "$SPACESHIP_GIT_WORKTREE_PREFIX" \
    --suffix "$SPACESHIP_GIT_WORKTREE_SUFFIX" \
    "$worktree_symbol"
}
