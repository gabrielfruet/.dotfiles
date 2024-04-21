#!/usr/bin/env zsh

styler_path="$HOME/.config/i3blocks/custom/styler.sh"

# Fetch battery status and level
BATTERY_PATH="/sys/class/power_supply/BAT0" # May need adjustment for your system
STATUS=$(cat "${BATTERY_PATH}/status")
CAPACITY=$(cat "${BATTERY_PATH}/capacity")

# Determine color based on battery level
if [ "$CAPACITY" -gt 50 ]; then
    COLOR="#9ECE6A" # Green
    TEXT_COLOR="#FFFFFF"
elif [ "$CAPACITY" -gt 25 ]; then
    COLOR="#FFEB3B" # Yellow
    TEXT_COLOR="#131620"
else
    COLOR="#F44336" # Red
    TEXT_COLOR="#FFFFFF"
fi


# Determine icon or text to display based on charging status
if [ "$STATUS" = "Charging" ]; then
    TEXT=""
else
    TEXT=""
fi

text_color="$TEXT_COLOR"
background="$COLOR"
pango_formatting() {
    echo "<span color=\"#${background}\"></span><span background=\"#${background}\" color=\"#${text_color}\"> $1   </span>"
}

# Output with Pango markup
"$styler_path" "$CAPACITY% $TEXT  " --n 0 --bg "$background" --txt "$text_color" --sep "\ue0b6"

