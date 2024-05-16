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
    feh --image-bg black --recursive --geometry 1200x600 --thumbnails --thumb-width 200 --thumb-height 200 --index-info '' --action "w= feh --bg-scale %f" "$WALLPAPERS" > /dev/null
    fehbgpath=$(awk 'FNR==2{print $4}' < ~/.fehbg | sed "s/'//g" ) 
    wal -st -i "$fehbgpath" --backend colorz
    awesome-client "awesome.restart()"
}

reload() {
    fehbgpath=$(awk 'FNR==2{print $4}' < ~/.fehbg | sed "s/'//g" ) 
    wal -st -i "$fehbgpath" --backend colorz
}

while getopts 'frh' opt; do
    case "$opt" in
        f)
            set_with_feh
            exit 0
            ;;
        r)
            reload
            exit 0
            ;;
        h|?)
            echo "invalid"
            ;;
    esac
done
