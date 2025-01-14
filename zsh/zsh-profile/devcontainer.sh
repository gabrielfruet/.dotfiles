#!/bin/env bash

dvc-build () {
    devcontainer build \
        --workspace-folder . \
        --log-level debug

}

dvc-up () {
    devcontainer up \
        --mount type=bind,source=/home/fruet/.config/nvim,target=/root/.config/nvim \
        --mount type=bind,source=/home/fruet/.local/share/nvim,target=/root/.local/share/nvim \
        --mount type=bind,source=/home/fruet/.local/state/nvim,target=/root/.local/state/nvim \
        --mount type=bind,source=/home/fruet/.cache/wal,target=/root/.cache/wal \
        --additional-features '{"ghcr.io/duduribeiro/devcontainer-features/neovim:1" :{}}' \
        --remove-existing-container \
        --log-level debug \
        --gpu-availability all \
        --workspace-folder .
}
