#!/bin/bash


styler_path="$HOME/.config/i3blocks/custom/styler.sh"

background="FF7C7C"
pango_formatting() {
    echo "<span><span color=\"#${background}\"></span><span background=\"#${background}\" color=\"#131620\">$1</span><span color=\"#${background}\"></span></span>"
}


case $BLOCK_BUTTON in
    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;  # Left click - Mute / Unmute
    4) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;   # Scroll up - Increase volume
    5) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;   # Scroll down - Decrease volume
esac

# Display the current volume and mute status
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+%' | head -1 | sed 's/%//')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(yes|no)')

if [ "$MUTE" = "yes" ]; then
    msg="󰖁 Mut"
elif [ "$VOL" -gt 50 ]; then
    msg=" $VOL%"
elif [ "$VOL" -lt 50 ]; then
    msg=" $VOL%"
else
    msg=" ?"
fi

"$styler_path" " $msg   " --n 2
