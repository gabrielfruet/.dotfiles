#!/usr/bin/env bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

disk_info="$(df -h / | awk 'NR == 2 { printf(" %4s / %s", $4, $2) }')"

"$styler_path" " $disk_info   " --n 5

