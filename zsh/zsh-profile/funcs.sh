#!/bin/env sh

vnv() {
    venv_path="$(pwd)/.venv"
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating venv"
        deactivate && tmux set-environment -r VIRTUAL_ENV && zsh
    elif [ -e "$venv_path" ]; then
        echo "Activating venv"
        . "$venv_path/bin/activate" &&
        tmux set-environment VIRTUAL_ENV "$venv_path" || echo "some error ocurred"
    fi
}
