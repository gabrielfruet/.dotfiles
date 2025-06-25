#!/bin/zsh

tokill=$(ps -u "$USER" -o pid,comm | dmenu -p "Kill")

kill $(echo "$tokill" | awk '{print $1}') 2>/dev/null


