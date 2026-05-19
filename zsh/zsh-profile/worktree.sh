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

worktree-remove () {
    selected_worktree=$(git worktree list | _label_worktree | column -t | fzf --ansi | awk '{print $2}')

    if [[ -z "$selected_worktree" ]]; then
        echo "No worktree selected"
        return 1
    fi

    sure_you_want_to_remove=$(printf "Yes\nNo" | fzf --prompt="Are you sure you want to remove $selected_worktree? (Yes/No) " --height=3 --border=rounded)

    if [[ "$sure_you_want_to_remove" != "Yes" ]]; then
        echo "Aborting worktree removal."
        return 1
    fi

    git worktree remove $selected_worktree
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

    if [[ -z "$dir" ]]; then
        echo "No worktree selected"
        return 1
    fi

    cd "$dir" || exit 1
}
