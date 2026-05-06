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
    local remote_ref=""
    local has_local_branch=0

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "not a git repo: $repo"
        return 1
    fi

    if git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        has_local_branch=1
    else
        while read -r remote; do
            [ -z "$remote" ] && continue
            if git -C "$repo" ls-remote --exit-code --heads "$remote" "$branch" >/dev/null 2>&1; then
                remote_ref="$remote/$branch"
                break
            fi
        done < <(git -C "$repo" remote)
    fi

    mkdir -p "$worktrees" || return 1

    if [ "$has_local_branch" -eq 1 ]; then
        git -C "$repo" worktree add "$wt" "$branch" || return 1
    elif [ -n "$remote_ref" ]; then
        git -C "$repo" worktree add -b "$branch" "$wt" "$remote_ref" || return 1
    else
        git -C "$repo" worktree add -b "$branch" "$wt" "$base_branch" || return 1
    fi

    if [ -e "$repo/.venv" ] && [ ! -e "$wt/.venv" ]; then
        ln -s "$repo/.venv" "$wt/.venv"
    fi

    cd "$wt" || return 1
}
