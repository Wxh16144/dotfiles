#!/bin/bash

function __internal__husky_init() {
  local __NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  
  [ -s "$__NVM_DIR/nvm.sh" ] && \. "$__NVM_DIR/nvm.sh"  # This loads nvm
}

__internal__husky_init
