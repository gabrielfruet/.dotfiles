#!/usr/bin/env bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

background="052b5a"
pango_formatting() {
    echo "<span color=\"#${background}\"></span><span background=\"#${background}\" color=\"#FFFFFF\"> $1   </span>"
}

ram_msg="$(free -h | awk '/Mem:/ { printf("RAM %5s / %s", $3, $2) }' | sed 's|Gi|G|g')"

"$styler_path" " $ram_msg   " --n 3
