#!/bin/zsh

. "$HOME/.zshrc"

CURR_WALLPAPER_PATH="$HOME/.cache/awesome/wallpaper"

fifo=/tmp/preview_wallpapers
selected_fifo=/tmp/selected_wallpaper

[[ -p "$fifo" ]] || mkfifo "$fifo"
[[ -p "$selected_fifo" ]] || mkfifo "$selected_fifo"

trap 'rm -f "$fifo" "$selected_fifo"' EXIT SIGINT

preview_wallpapers() {
    fd ".png|.jpg|.jpeg" "$WALLPAPERS" | shuf | dmenu -ps -l 10> "$fifo"
}

(
    selected=""
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        selected="$line"
        feh --bg-fill --no-fehbg "$line"
    done < "$fifo"

    echo "$selected" > "$selected_fifo"
) &

preview_wallpapers
dmenu_exit_code=$?
rm -f "$fifo"

if [[ $dmenu_exit_code -eq 0 ]]; then
    selected=$(cat "$selected_fifo")
    notify-send "Selected wallpaper: $selected"
    wal -stn -i "$selected" --backend wal
    xrdb -merge ~/.cache/wal/colors-dmenu.Xresources
    echo "$CURR_WALLPAPER_PATH"
    echo "$selected" > "$CURR_WALLPAPER_PATH"
    cat "$CURR_WALLPAPER_PATH" && \
        echo 'awesome.restart()' | awesome-client
else
    notify-send "No wallpaper selected."
fi

feh --bg-fill $(cat "$CURR_WALLPAPER_PATH")

rm -f "$fifo" "$selected_fifo"
