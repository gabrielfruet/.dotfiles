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

case $selected in
    "all")
        scrot -q 100 -d "$DELAY" "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png";;
    "select")
        scrot -q 100 -s --line color=#ff0000 "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png";;
    "focus")
        scrot -q 100 -u -d "$DELAY" "$SCROT_FOLDER/screenshot_%Y-%m-%d_%H:%M:%S.png";;
    "gui")
        flameshot gui --delay 500
esac
