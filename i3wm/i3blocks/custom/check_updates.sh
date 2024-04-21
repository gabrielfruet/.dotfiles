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
fedora

"$styler_path" "$symbol   " --bg "$color" --txt "$txt_color" --n 0 --sep "\ue0b6"
