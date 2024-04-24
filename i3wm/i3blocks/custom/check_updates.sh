#!/usr/bin/env bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

fedora() {
    # Check for updates
    UPDATES=$(dnf check-update --quiet | grep -c '^[[:alpha:]]')

    if [ "$UPDATES" -gt 0 ]; then
        color="#FFEB3B" # Yellow
        txt_color="#131620"
        symbol=""
    else
        color="#9ECE6A" # Green
        txt_color="#FFFFFF"
        symbol=""
    fi
}

archlinux() {
    UPDATES=$(pacman -Qu)
    if [ -n "$UPDATES" ]; then
        color="#FFEB3B" # Yellow
        txt_color="#131620"
        symbol=""
    else
        color="#9ECE6A" # Green
        txt_color="#FFFFFF"
        symbol=""
    fi
}

osname="$(hostnamectl | sed -n 's/^ *Operating System: \(.*\)$/\1/p' | sed 's/ //g' | tr '[:upper:]' '[:lower:]')"

case $osname in
    archlinux) archlinux;;
    fedora) fedora;;
esac


"$styler_path" "$symbol   " --bg "$color" --txt "$txt_color" --n 0 --sep "\ue0b6"
