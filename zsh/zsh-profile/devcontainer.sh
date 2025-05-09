#!/bin/env bash

dvc-build () {
    devcontainer build \
        --workspace-folder . \
        --log-level debug

}


get_container_user() {
    python <<EOF
import json
with open(".devcontainer/devcontainer.json") as f:
    data = json.load(f)
    user = data.get('containerUser')
    if user is not None:
        print(user)
EOF
}

dvc-up () {
    user_name=$(get_container_user)
    if [ -z "$user_name" ]; then
        user_name="root"
    fi

    echo "Container user is $user_name" 

    devcontainer up \
        --mount "type=bind,source=$HOME/.config/nvim,target=/home/$user_name/.config/nvim" \
        --mount "type=bind,source=$HOME/.local/share/nvim,target=/home/$user_name/.local/share/nvim" \
        --mount "type=bind,source=$HOME/.local/state/nvim,target=/home/$user_name/.local/state/nvim" \
        --mount "type=bind,source=$HOME/.cache/wal,target=/home/$user_name/.cache/wal" \
        --mount "type=bind,source=/tmp/tmux-1000/,target=/tmp/tmux-1000/" \
        --mount "type=bind,source=$HOME/.gitconfig,target=/home/$user_name/.gitconfig" \
        --mount "type=bind,source=$HOME/.ssh,target=/home/$user_name/.ssh" \
        --remote-env "GIT_SSH_COMMAND=ssh -o StrictHostKeyChecking=no" \
        --additional-features '{
            "ghcr.io/devcontainers/features/git:1": {}
            "ghcr.io/devcontainers-extra/features/fzf:1" : {}
            "ghcr.io/duduribeiro/devcontainer-features/neovim:1" :{}
            "ghcr.io/duduribeiro/devcontainer-features/tmux:1": {}
            "ghcr.io/devcontainers/features/node:1": {
                "version": "16"
            }
        }' \
        --remove-existing-container \
        --log-level debug \
        --gpu-availability all \
        --workspace-folder .
}
