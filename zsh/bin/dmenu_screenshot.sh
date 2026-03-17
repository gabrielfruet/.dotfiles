#!/bin/bash

opts=(
    "all"
    "select"
    "focus"
    "gui"
)

SCROT_FOLDER="${HOME}/Pictures/screenshots"
mkdir -p "$SCROT_FOLDER"

selected=$(printf "%s\n" "${opts[@]}" | dmenu -l 10)

DELAY=1
SCROT_COPY_TO_CLIPBOARD='xclip -selection clipboard -t image/png -i "$f"'

case $selected in
    "all")
        scrot -q 100 -d "$DELAY" "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png" -e  "$SCROT_COPY_TO_CLIPBOARD";; 
    "select")
        scrot -q 100 -s --line color="#ff0000" "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png" -e "$SCROT_COPY_TO_CLIPBOARD";;
    "focus")
        scrot -q 100 -u -d "$DELAY" "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png" -e "$SCROT_COPY_TO_CLIPBOARD";;
    "gui")
        flameshot gui --delay 500
esac
