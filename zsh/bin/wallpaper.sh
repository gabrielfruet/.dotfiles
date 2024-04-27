#!/bin/env sh

set -e

is_setting=false

NITROGEN_CONFIG_PATH="$CONFIG/nitrogen/bg-saved.cfg"

get_nitrogen_wallpaper_name() {
    while IFS='=' read -r key value; do
        case $key in 
            file) 
                echo "$value"
                return
                ;;
        esac
    done < "$NITROGEN_CONFIG_PATH"
}

set_with_feh() {
    feh --image-bg black --recursive --auto-zoom --geometry 1200x600 --thumbnails --thumb-width 200 --thumb-height 200 --index-info '' --action "w= feh --bg-scale %f" "$WALLPAPERS"
    fehbgpath=$(awk 'FNR==2{print $4}' < ~/.fehbg | sed "s/'//g" ) 
    echo fehbgpath
    wal -i "$fehbgpath" --backend haishoku
    echo 'awesome.restart()' | awesome-client
}

while getopts 'spfh' opt; do
    case "$opt" in
        s)
            is_setting=true
            ;;
        p)
            get_nitrogen_wallpaper_name
            exit 0
            ;;
        f)
            set_with_feh
            exit 0
            ;;
        ?)
            echo "invalid"
            ;;
    esac
done

if $is_setting; then
    nitrogen "$WALLPAPERS"
    wallpaper_path="$(get_nitrogen_wallpaper_name)"
    wal -i "$wallpaper_path" --backend haishoku
    nitrogen --restore
else
    cat /home/gabrielfruet/.cache/wal/sequences
    nitrogen --restore
fi
