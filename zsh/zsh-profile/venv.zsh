#!/bin/env zsh

autoload -U add-zsh-hook

auto_activate_venv() {
    if [[ -f .venv/bin/activate ]]; then
        export VIRTUAL_ENV_DISABLE_PROMPT=1
        source .venv/bin/activate
    elif [[ -n "$VIRTUAL_ENV" ]] && (( ${+functions[deactivate]} )); then
        deactivate
    fi
}

add-zsh-hook chpwd auto_activate_venv
auto_activate_venv

svnv() {
    local -a venvs
    local selected venv_name

    venvs=(${(@f)$(find . -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/bin/activate' \; -print | sed 's#^\./##' | sort)})

    if (( ${#venvs[@]} == 0 )); then
        printf 'svnv: no local virtualenvs found in %s\n' "$PWD" >&2
        return 1
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        printf 'svnv: fzf is not installed\n' >&2
        return 1
    fi

    selected=$(printf '%s\n' "${venvs[@]}" | fzf --prompt='svnv> ' --header='select a virtualenv') || return 1
    [[ -n "$selected" ]] || return 1

    venv_name=${selected:t}

    if [[ -n "$VIRTUAL_ENV" ]] && (( ${+functions[deactivate]} )); then
        deactivate
    fi

    export VIRTUAL_ENV_DISABLE_PROMPT=1

    if source "./$selected/bin/activate"; then
        printf 'svnv: activated %s\n' "$venv_name"
    else
        printf 'svnv: failed to activate %s\n' "$selected" >&2
        return 1
    fi
}
