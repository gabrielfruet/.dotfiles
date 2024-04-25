#!/bin/env zsh

vnv() {
    venv_path="$(pwd)/.venv/bin/activate"
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "Deactivating venv"
        deactivate && zsh
    elif [[ -f "$venv_path" ]]; then
        echo "Activating venv"
        source "$venv_path"
    fi
}
