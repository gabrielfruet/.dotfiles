#!/bin/env zsh

_ssh_is_config_query() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -V|-Q|-G)
                return 0
                ;;
        esac
    done

    return 1
}

ssh() {
    if _ssh_is_config_query "$@"; then
        command ssh "$@"
        return $?
    fi

    # No keys loaded — load the last used keychain.
    if ! ssh-add -l >/dev/null 2>&1; then
        keychain -l || return 1
    fi

    command ssh "$@"
}
