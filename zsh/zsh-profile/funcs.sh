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
    case "${1:-}" in
        -h|--help|help)
            cat <<'EOF'
Usage: lw <repo> <branch> [base-branch]

Create a git worktree for <branch> under <repo>-worktrees/<branch>.
If the branch exists locally, it is used directly. Otherwise, remote
branches are checked and [base-branch] (default: main) is used as fallback.

A virtualenv is NOT created, copied, or cloned for the worktree (venvs
embed absolute paths, so sharing or symlinking one is broken). Create
the worktree's own venv manually when needed, e.g. run `uv sync`.

Examples:
  lw ~/src/project feature/foo
  lw ~/src/project feature/foo develop
EOF
            return 0
            ;;
    esac

    local repo="${1:?repo path required}"
    local branch="${2:?branch name required}"
    local base_branch="${3:-main}"
    local safe_branch="${branch//\//-}"
    local repo_root="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null)" || {
        echo "not a git repo: $repo"
        return 1
    }
    local repo_name="$(basename "$repo_root")"
    local worktrees="$(dirname "$repo_root")/${repo_name}-worktrees"
    local wt="$worktrees/$safe_branch"
    local remote_ref=""
    local has_local_branch=0

    if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "not a git repo: $repo"
        return 1
    fi

    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
        has_local_branch=1
    else
        while read -r remote; do
            [ -z "$remote" ] && continue
            if git -C "$repo_root" ls-remote --exit-code --heads "$remote" "$branch" >/dev/null 2>&1; then
                remote_ref="$remote/$branch"
                break
            fi
        done < <(git -C "$repo_root" remote)
    fi

    mkdir -p "$worktrees" || return 1

    if [ "$has_local_branch" -eq 1 ]; then
        git -C "$repo_root" worktree add "$wt" "$branch" || return 1
    elif [ -n "$remote_ref" ]; then
        git -C "$repo_root" worktree add -b "$branch" "$wt" "$remote_ref" || return 1
    else
        git -C "$repo_root" worktree add -b "$branch" "$wt" "$base_branch" || return 1
    fi

    cd "$wt" || return 1
}
