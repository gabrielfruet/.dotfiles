#!/bin/env bash

YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
CYAN='\033[96m'
NC='\033[0m'

args="--ignore=pkg --verbose=3 --dotfiles"

runstow() {
    current_dir="$1"
    pkg_path="$1/pkg"
    target="$HOME"
    ignore=""

    echo -e "${LBLUE}Running stow at: $current_dir ${NC}"

    while IFS='=' read -r key value; do
        case $key in 
            target) 
                target="$(echo "$value" | envsubst)"
                ;;
            ignore)
                ignore="$value"
                ;;
        esac
    done < "$pkg_path"

    echo -e "${CYAN}Target: $target${NC}"

    specargs="$args"
    specargs="$specargs --target=$target --dir=$current_dir"
    if [[ -n "$ignore" ]]; then
        specargs="$specargs --ignore=${ignore}" 
    fi

    echo -e "${BLUE}Running:${NC}\n${LBLUE} stow $specargs . ${NC}"

    echo -e "${YELLOW}"
    stow $specargs .
    echo -e "${NC}"
}

stow_packages() {
    current_dir="$1"
    pkg_path="$current_dir/pkg"

    if [ -f "$pkg_path" ]; then
        runstow "$current_dir"
    else
        echo -e "${BLUE}Entering $(realpath "$current_dir") ${NC}"
        for dir in "$current_dir"/*/; do
            if [ -d "$dir" ]; then  
                clean_dir="$(realpath "$dir")"
                stow_packages "$clean_dir"  
            fi
        done;
    fi
}


while getopts 'suh' opt; do
    case "$opt" in
        s)
            args="-n $args"
            ;;
        u)
            args="-D $args"
            ;;
        h|?)
            echo "Usage: $(basename "$0") [-s] [-t] [-u]"
            echo "-s -> Simulate symlinks, like stow -n ..."
            echo "-t -> Delete symlinks, like stow -D ..."
            exit 1
            ;;
    esac
done


stow_packages .