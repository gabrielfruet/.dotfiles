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
