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

git_global_run() {
    # Capture the output of `globalgit.sh show`
    local cmd
    cmd=$(globalgit.sh echo)
    
    # Check if the command is not empty
    if [[ -z "$cmd" ]]; then
        echo "Did not select any command"
        return 1
    fi
    
    # Execute the command in the current shell
    eval "$cmd"
}

