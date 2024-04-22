#!/bin/env zsh

# ** WARNING **
# NECESSARY FOR tmuxss.sh working with python venv
if [[ $TMUX ]]; then
    if [[ $VIRTUAL_ENV ]]; then
        source "$VIRTUAL_ENV/bin/activate"
    fi
fi
