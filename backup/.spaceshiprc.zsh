
# https://spaceship-prompt.sh/blog/2022-spaceship-v4/#Asynchronous-rendering
SPACESHIP_PROMPT_ASYNC=false

# my custom
# spaceship add commit_hash --before git
prompt_order="$SPACESHIP_PROMPT_ORDER"

# My PR has been merged and can now be used directly. (No need to customize, if you want to customize, you can refer to it.).
# PR: https://github.com/spaceship-prompt/spaceship-prompt/pull/741
# if [[ $prompt_order != *commit_hash* ]]; then
#   spaceship add commit_hash --after git
# fi

# react
if [[ $prompt_order != *react* ]]; then
  spaceship add react --after package
fi


# https://spaceship-prompt.sh/sections/git/#Git-commit-git_commit
# https://github.com/spaceship-prompt/spaceship-prompt/pull/741
SPACESHIP_GIT_COMMIT_SHOW=true