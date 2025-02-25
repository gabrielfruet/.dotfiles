#!/bin/bash

MAGENTA='\e[35m'
YELLOW='\033[93m'
RESET='\e[0m'

_label_worktree() {
    while read -r line; do
        read -r path hash branch <<< "$line"
        echo -e "$MAGENTA$branch$RESET $YELLOW$path$RESET $hash"
    done
}

worktree-switch () {
    dir=$(
        git worktree list |
        _label_worktree |
        column -t |
        fzf \
        --tmux center,50% \
        --ansi |
        awk '{print $2}'
    )
    cd "$dir" || exit 1
}
