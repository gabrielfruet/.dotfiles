#!/bin/bash

set -e
 
gum spin --title "Saving Arch Packages" -- pacman -Qqe > packages.txt
gum spin --title "Saving Arch User Repository Packages" -- pacman -Qqm > aur-packages.txt

