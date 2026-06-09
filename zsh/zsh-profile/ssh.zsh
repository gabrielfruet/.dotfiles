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

    # If keys are already loaded in the agent, ssh directly without prompting.
    if ssh-add -l >/dev/null 2>&1; then
        command ssh "$@"
        return $?
    fi

    # No keys loaded — offer to start keychain.
    if ! command -v keychain >/dev/null 2>&1; then
        print -r -- "No SSH keys loaded and keychain is not installed. Aborting."
        return 130
    fi

    print -n -- "No SSH keys loaded. Start keychain? [Y/n]: "
    local reply
    read -r reply

    case "${reply:l}" in
        n|no)
            print -r -- "SSH aborted."
            return 130
            ;;
        ""|y|yes)
            keychain || return 1
            ;;
        *)
            print -r -- "Please answer yes or no."
            return 130
            ;;
    esac

    command ssh "$@"
}
