#!/bin/env bash

dvc-build () {
    devcontainer build \
        --workspace-folder . \
        --log-level debug

}


get_container_user() {
    jq -r '.containerUser // ""' .devcontainer/devcontainer.json
}

dvc-up () {
    flags=()
    user_name=""

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --*) # If it starts with --, treat as flag
                flags+=("$arg")
                ;;
            *) # Otherwise assume it's the username
                user_name="$arg"
                ;;
        esac
    done

    if [ -z "$user_name" ]; then
        # fallback to helper or default
        user_name=$(get_container_user)
    fi
    if [ -z "$user_name" ]; then
        user_name="root"
    fi

    echo "Container user is $user_name"
    echo "Leading flags: ${flags[*]}"

    devcontainer up \
        "${flags[@]}" \
        --workspace-folder . \
        --log-level debug \
        --gpu-availability all  \
        --mount "type=bind,source=$HOME/.config/nvim,target=/home/$user_name/.config/nvim" \
        --mount "type=bind,source=$HOME/.local/share/nvim,target=/home/$user_name/.local/share/nvim" \
        --mount "type=bind,source=$HOME/.local/state/nvim,target=/home/$user_name/.local/state/nvim" \
        --mount "type=bind,source=$HOME/.cache/wal,target=/home/$user_name/.cache/wal" \
        --mount "type=bind,source=/tmp/tmux-1000/,target=/tmp/tmux-1000/" \
        --mount "type=bind,source=$HOME/.gitconfig,target=/home/$user_name/.gitconfig" \
        --mount "type=bind,source=$HOME/.ssh,target=/home/$user_name/.ssh" \
        --mount "type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix" \
        --remote-env "GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=no" \
        --remote-env "DISPLAY=$DISPLAY" \
        --additional-features '{
            "ghcr.io/devcontainers/features/git:1": {},
            "ghcr.io/devcontainers-extra/features/fzf:1": {},
            "ghcr.io/duduribeiro/devcontainer-features/neovim:1": {},
            "ghcr.io/duduribeiro/devcontainer-features/tmux:1": {},
            "ghcr.io/devcontainers/features/node:1": { "version": "lts" }
        }'
}
