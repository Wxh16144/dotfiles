#!/usr/bin/bash

safe_run_path="/Users/wuxh/Code/SelfProject/dotfiles"

function before_check() {
  # Determine if the current execution script address is `/wuxh/test`
  if [ $(pwd) != $safe_run_path ]; then
    echo "please run in $safe_run_path"
    exit 1
  fi

  if [ $(git diff --name-only | wc -l) -ne 1 ] || [ $(git diff --name-only) != ".mackup_public.cfg" ]; then
    echo "please only change .mackup_public.cfg file"
    exit 1
  fi
}

# Check the `mackup` directory
function check_mackup() {
  # directory exist and is not a symlink, backup
  if [ -e ~/.mackup ] && [ ! -L ~/.mackup ]; then
    mv ~/.mackup ~/.mackup_$(date +%Y%m%d%H%M%S)_bak
    rm -rf ~/.mackup
  fi

  # create symlink
  if [ ! -L ~/.mackup ]; then
    ln -s $(pwd)/.mackup ~/.mackup
  fi

  echo "check mackup success"
}

# Use the private configuration to back up the entire side
function mackup_all_backup() {
  # mackup uninstall
  mackup -f uninstall

  # restore .mackup.cfg (private config)
  cp .mackup.cfg ~/.mackup.cfg

  # mackup backup
  mackup -fv backup

  echo "mackup all backup success"
}

# Backup public sharing
function mackup_public_backup() {
  # mackup uninstall
  mackup -f uninstall

  # override .mackup.cfg (public config)
  cp .mackup_public.cfg ~/.mackup.cfg

  # mackup backup
  mackup -fv backup

  echo "mackup public backup success"
}

function reset() {
  # mackup uninstall
  mackup -f uninstall

  # restore .mackup.cfg (private config)
  cp .mackup.cfg ~/.mackup.cfg

  # mackup backup
  mackup -fv backup
}

function main() {
  before_check
  check_mackup
  mackup_all_backup
  mackup_public_backup
  reset
}

main "$@"