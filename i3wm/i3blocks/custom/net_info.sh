#!/usr/bin/env bash

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

# Replace eth0 with your actual network interface name
INTERFACE="wlo1"

# Fetch current network traffic
NETWORK=$(vnstat -i $INTERFACE --oneline)

# Parse the download and upload speeds
DOWNLOAD=$(echo "$NETWORK" | cut -d ";" -f 5 | sed 's|MiB|Mb|g')
UPLOAD=$(echo "$NETWORK" | cut -d ";" -f 6 | sed 's|MiB|Mb|g')

# Display the results
msg=" $DOWNLOAD  $UPLOAD"
"$styler_path" "$msg   " --n 6
