#!/usr/bin/env bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

background="052b5a"
pango_formatting() {
    echo "<span color=\"#${background}\"></span><span background=\"#${background}\" color=\"#FFFFFF\"> $1   </span>"
}

datemsg="$(date +"%a, %d %b - %H:%M:%S")"

"$styler_path" " $datemsg   "  --n 1


