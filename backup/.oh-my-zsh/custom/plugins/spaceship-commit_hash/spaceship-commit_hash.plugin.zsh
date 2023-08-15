# PR: https://github.com/spaceship-prompt/spaceship-prompt/pull/741
# Custom information of your choice: https://spaceship-prompt.sh/advanced/creating-section/
# ref: https://github.com/spaceship-prompt/spaceship-section/blob/055939cb13de632c8294637c2576bdc9be46bc5f/spaceship-section.plugin.zsh

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------
SPACESHIP_COMMIT_HASH_SHOW="${SPACESHIP_COMMIT_HASH_SHOW=true}"
SPACESHIP_COMMIT_HASH_ASYNC="${SPACESHIP_COMMIT_HASH_ASYNC=true}"
SPACESHIP_COMMIT_HASH_PREFIX="${SPACESHIP_COMMIT_HASH_PREFIX="$SPACESHIP_PROMPT_DEFAULT_PREFIX"}"
SPACESHIP_COMMIT_HASH_SUFFIX="${SPACESHIP_COMMIT_HASH_SUFFIX=" "}"
SPACESHIP_COMMIT_HASH_SYMBOL="${SPACESHIP_COMMIT_HASH_SYMBOL="#"}"
SPACESHIP_COMMIT_HASH_COLOR="${SPACESHIP_COMMIT_HASH_COLOR="yellow"}"

# ------------------------------------------------------------------------------
# Section
# ------------------------------------------------------------------------------
spaceship_commit_hash() {
  [[ $SPACESHIP_COMMIT_HASH_SHOW == false ]] && return

  local commit_hash="$(git rev-parse --short HEAD 2>/dev/null)"

  [[ -z "$commit_hash" ]] && return
  
  spaceship::section::v4 \
    --color "$SPACESHIP_COMMIT_HASH_COLOR" \
    --prefix "$SPACESHIP_COMMIT_HASH_PREFIX" \
    --suffix "$SPACESHIP_COMMIT_HASH_SUFFIX" \
    --symbol "$SPACESHIP_COMMIT_HASH_SYMBOL" \
    "$commit_hash"
}
