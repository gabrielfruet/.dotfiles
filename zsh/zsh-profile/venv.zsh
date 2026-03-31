#!/bin/env zsh

autoload -U add-zsh-hook

auto_activate_venv() {
    if [[ -f .venv/bin/activate ]]; then
        export VIRTUAL_ENV_DISABLE_PROMPT=1
        source .venv/bin/activate
    elif [[ -n "$VIRTUAL_ENV" ]]; then
        export VIRTUAL_ENV=""
    fi
}

add-zsh-hook chpwd auto_activate_venv
auto_activate_venv
