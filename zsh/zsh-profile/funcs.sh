#!/bin/env bash

vnv() {
    venv_path="$(pwd)/.venv"
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating venv"
        deactivate
        if [ -n "$TMUX" ]; then
            tmux set-environment -r VIRTUAL_ENV \
                && . "$HOME/.zshrc"
        fi
    elif [ -e "$venv_path" ]; then
        echo "Activating venv"
        . "$venv_path/bin/activate" \
            || echo "some error occured" 

        if [ -n "$TMUX" ]; then
            tmux set-environment VIRTUAL_ENV "$venv_path"
        fi
    fi
}

notify-finish() {
    notify-send "Command 🛠️" "Command has finished execution"
}

lw() {
    local repo="${1:?repo path required}"
    local branch="${2:?branch name required}"
    local base_branch="${3:-main}"
    local safe_branch="${branch//\//-}"
    local worktrees="${repo%/}-worktrees"
    local wt="$worktrees/$safe_branch"

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "not a git repo: $repo"
        return 1
    fi

    mkdir -p "$worktrees" || return 1
    git -C "$repo" worktree add -b "$branch" "$wt" "$base_branch" || return 1

    if [ -e "$repo/.venv" ] && [ ! -e "$wt/.venv" ]; then
        ln -s "$repo/.venv" "$wt/.venv"
    fi

    cd "$wt" || return 1
}
