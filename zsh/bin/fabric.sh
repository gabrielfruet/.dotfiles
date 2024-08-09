#!/bin/env bash

set -e

# Initialize variables (optional, but good practice)
model=""
pattern=""

# Use getopts to parse arguments
while getopts ":m:p:" opt; do
    case $opt in
        m) model="$OPTARG" ;;
        p) pattern="$OPTARG" ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1 ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1 ;;
    esac
done

# Check for missing arguments
if [ -z "$model" ]; then
    # Replace "your_file.txt" with the file you want to check
    file="$HOME/.cache/fabric/models-list.txt"

    update_file() {
        fabric --listmodels | grep -Ev "(Models:$|^$)" > "$file"
    }

    if [ -e "$file" ]; then
        current_date=$(date +%s)
        file_creation_date=$(stat -c %W "$file")
        diff_days=$(( (current_date - file_creation_date) / 86400 ))

        if [ "$diff_days" -gt 7 ]; then
            update_file
        fi
    else 
        update_file
    fi

    models="$(cat "$file")"

    model="$(echo -e "$models" | fzf)"
fi

if [ -z "$pattern" ]; then
    patterns_dir="$HOME/apps/fabric/patterns"
    pattern="$(ls "$patterns_dir" | fzf --preview "less $patterns_dir/{}/system.md")"
fi

fabric --pattern "$pattern" --model "$model"
