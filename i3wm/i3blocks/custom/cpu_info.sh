#!/bin/bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"
# Read /proc/stat file (contains CPU stats)
read -r cpu a b c idle rest < /proc/stat

# Calculate total CPU time
prev_total=$((a+b+c+idle))
prev_idle=$idle

sleep 1

# Read /proc/stat file again for updated stats
read -r cpu a b c idle rest < /proc/stat

# Calculate total CPU time again
total=$((a+b+c+idle))

# Calculate the CPU usage since last check
cpu=$((100*( (total-prev_total) - (idle-prev_idle) ) / (total-prev_total) ))

"$styler_path" "  $cpu%   " --n 4

