# #!/bin/bash

# chmod 755 $ZSH_CUSTOM/shells/code-wait.sh
# see: https://stackoverflow.com/a/65142525

OPTS=""
if [[ "$1" == /tmp/* ]]; then
    OPTS="-w"
fi

CODE=$(which code)

CODE ${OPTS:-} -a "$@"
