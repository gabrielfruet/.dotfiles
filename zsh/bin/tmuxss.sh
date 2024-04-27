#!/usr/bin/env sh

set -eu

selected=$(find "$TMUXSS" -type f -printf '%P\n' | fzf)

sessions_running=$(tmux ls | awk '{print $1}' | sed 's/://')

if echo "$sessions_running" | grep  -q "$selected" ; then
    echo "Session is already running."
    echo "Do you want to attach it? (y/n)"
    read -r ans
    if [ "$ans" = "y" ]; then
        tmuxat.sh "$selected"
    else
        exit 1
    fi
    exit 0
fi

"$TMUXSS/$selected"
