#!/usr/bin/bash

function replace {
  # https://stackoverflow.com/a/4247319/11302760
  sed -i'.bak' -e "s|path = .*|path = $(pwd)|g" ./.mackup_public.cfg

  echo "replace success"
}

# Check the `mackup` directory
function check_mackup() {
  # directory exist and is not a symlink, backup
  if [ -e ~/.mackup ] && [ ! -L ~/.mackup ]; then
    mv ~/.mackup ~/.mackup_$(date +%Y%m%d%H%M%S)_bak
    rm -rf ~/.mackup
  fi

  if [ -e ~/.mackup.cfg ] && [ ! -L ~/.mackup.cfg ]; then
    mv ~/.mackup.cfg ~/.mackup.cfg_$(date +%Y%m%d%H%M%S)_bak
    rm -rf ~/.mackup.cfg
  fi

  echo "check mackup success"
}

# soft link
function link {
  if [ ! -L ~/.mackup ]; then
    ln -s $(pwd)/.mackup ~/.mackup
  fi

  if [ ! -L ~/.mackup.cfg ]; then
    ln -s $(pwd)/.mackup_public.cfg ~/.mackup.cfg
  fi

  echo "link success"
}

# check macup is installed
function check_isinstall() {
  if ! command -v mackup &> /dev/null
  then
    echo "mackup could not be found"
    exit
  fi
}

function main() {
  check_isinstall
  before_check
  replace
  link

  # restore
  mackup -frv restore
}

main
