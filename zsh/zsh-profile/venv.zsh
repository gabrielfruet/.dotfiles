#!/bin/env zsh

# Ensure the hook system is loaded
autoload -U add-zsh-hook

# Define the function
auto_activate_venv() {
    if [[ -f .venv/bin/activate ]]; then
        export VIRTUAL_ENV_DISABLE_PROMPT=1
        source .venv/bin/activate
    # Deactivate if leaving the environment directory
    elif [[ -n "$VIRTUAL_ENV" && ! -f .venv/bin/activate ]]; then
        deactivate
    fi
}

# Attach the function to the directory change event
add-zsh-hook chpwd auto_activate_venv

auto_activate_venv  # Run it once for the current directory
