#!/usr/bin/env bash

if [ -z "$(pgrep tmux)" ]; then
    echo "Tmux is not running."
    exit 1
fi

if [ -n "$TMUX" ]; then
    session=$(tmux ls | sed 's/://' | awk '{print $1}' | fzf)
    tmux attach-session -t "$session"
    exit 1
fi

if [ -z "$1" ]; then
    session=$(tmux ls | sed 's/://' | awk '{print $1}' | fzf)
    tmux attach -t "$session"
    exit 0
fi

tmux attach -t "$1"
exit 1
