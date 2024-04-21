#!/usr/bin/env zsh

SLANT_SEPARATOR='\ue0b2'
ROUND_SEPARATOR='\ue0b6'

text="$1"

while [ $# -gt 0 ]; do
    if [[ $1 == "--"* ]]; then
        v="${1/--/}"
        declare "$v"="$2"
        shift
    fi
    shift
done

if [[ -z $n ]]; then
    echo "missing argument '-n'"
    exit 1
fi

slant_formatting() {
    if [[ -z "$bg" ]] || [[ -z "$txt" ]]; then
        if [ $(("$n" % 2)) -eq 1 ]; then
            bg="#052b5a" # navy blue
            txt="#ffffff" # white
        else
            bg="#ff7c7c" # tokyonight red
            txt="#131620" # dark blue
        fi
    fi

    separator=$SLANT_SEPARATOR
    if [[ "$sep" ]]; then
        separator=$sep
    fi

    slant_span_args="color=\"${bg}\""
    text_span_args="background=\"${bg}\" color=\"${txt}\""
     
    echo "<span><span ${slant_span_args}>${separator}</span><span ${text_span_args}>${1}</span></span>"
}

slant_formatting "$text"

