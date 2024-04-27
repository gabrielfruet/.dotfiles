#!/usr/bin/env bash

langpath="$HOME/bin/cht.sh-langs"
utilspath="$HOME/bin/cht.sh-utils"


languages=$(cat "$langpath")
core_utils=$(cat "$utilspath")

if [ "$1" = "-al" ]; then
    echo "What language you want to add?" 
    read -r newlang
    if echo "$languages" | grep -qs "$newlang"; then
        echo "Language already registered"
        exit 1
    fi
    echo "$newlang" >> "$langpath" 
    echo "Sucessfull!"
    exit 0
fi

if [ "$1" = "-ac" ]; then
    echo "What tool you want to add?" 
    read -r newtool
    newtool=$(echo "$newtool" | tr "[:upper:]" "[:lower:]")
    if echo "$core_utils" | grep -qs "$newtool"; then
        echo "Tool already registered"
        exit 1
    fi
    echo "$newtool" >> "$utilspath"
    echo "Sucessfull!"
    exit 0

fi

selected=$(printf "%s\n%s" "$languages" "$core_utils"| fzf --header="Choose a language or a tool for searching")

query=$(gum input --placeholder "Enter query")

if echo "$languages" | grep -qs "$selected"; then
    tmux neww bash -c "curl cht.sh/$selected/$(echo "$query" | tr ' ' '+') & while [ : ]; do sleep 1; done" 
else
    tmux neww bash -c "curl cheat.sh/$selected~$(echo "$query" | tr ' ' '+') & while [ : ]; do sleep 1; done"
fi

