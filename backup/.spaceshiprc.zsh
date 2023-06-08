
# https://spaceship-prompt.sh/blog/2022-spaceship-v4/#Asynchronous-rendering
SPACESHIP_PROMPT_ASYNC=false

# my custom
# spaceship add commit_hash --before git
prompt_order="$SPACESHIP_PROMPT_ORDER"

if [[ $prompt_order != *commit_hash* ]]; then
  spaceship add commit_hash --after git
fi

# react
if [[ $prompt_order != *react* ]]; then
  spaceship add react --after package
fi
