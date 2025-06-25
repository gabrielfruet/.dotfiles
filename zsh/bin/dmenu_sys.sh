#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

opts=(
    "☠ kill" 
    "⎙ screenshot"
    "usage"
    "shutdown"
    "reboot"
    "wallpaper"
)

selected=$(printf "%s\n" "${opts[@]}" | dmenu -l 10)

case $selected in
    "☠ kill")
        "$SCRIPT_DIR"/dmenu_kill.sh;;
    "shutdown")
        shutdown now;;
    "reboot")
        shutdown -r now;;
    "usage")
        ps -u "$USER" -o %mem,comm | dmenu -p "RAM";;
    "wallpaper")
        "$SCRIPT_DIR"/dmenu_wallpaper.sh;;
    "⎙ screenshot")
        "$SCRIPT_DIR"/dmenu_screenshot.sh;;
esac
