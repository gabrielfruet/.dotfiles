#!/bin/env bash

# Gruvbox Color Palette
DARK0_HARD="#1d202100"
DARK0="#282828"
DARK1="#3c3836"
DARK2="#504945"
DARK3="#665c54"
DARK4="#7c6f64"
LIGHT0="#fbf1c7"
LIGHT1="#ebdbb2"
LIGHT2="#d5c4a1"
LIGHT3="#bdae93"
LIGHT4="#a89984"
BRIGHT_RED="#fb4934"
BRIGHT_GREEN="#b8bb26"
BRIGHT_YELLOW="#fabd2f"
BRIGHT_BLUE="#83a598"
BRIGHT_PURPLE="#d3869b"
BRIGHT_AQUA="#8ec07c"
BRIGHT_ORANGE="#fe8019"

# Gum Colors
export GUM_CONFIRM_PROMPT_FOREGROUND=$LIGHT0
export GUM_CONFIRM_PROMPT_BACKGROUND=""
export GUM_CONFIRM_SELECTED_FOREGROUND=$DARK0_HARD
export GUM_CONFIRM_SELECTED_BACKGROUND=$BRIGHT_GREEN
export GUM_CONFIRM_UNSELECTED_FOREGROUND=$LIGHT2
export GUM_CONFIRM_UNSELECTED_BACKGROUND=$DARK1

export GUM_FILTER_PROMPT_FOREGROUND=$LIGHT0
export GUM_FILTER_PROMPT_BACKGROUND=""
export GUM_FILTER_SELECTED_FOREGROUND=$DARK0_HARD
export GUM_FILTER_SELECTED_BACKGROUND=$BRIGHT_GREEN
export GUM_FILTER_INDICATOR_FOREGROUND=$BRIGHT_GREEN
#export GUM_FILTER_INDICATOR_BACKGROUND=$BRIGHT_GREEN
export GUM_FILTER_UNSELECTED_FOREGROUND=$LIGHT2
export GUM_FILTER_UNSELECTED_BACKGROUND=$DARK1

export GUM_INPUT_PROMPT_FOREGROUND=$BRIGHT_BLUE
export GUM_INPUT_PROMPT_BACKGROUND=$DARK0
export GUM_INPUT_FOREGROUND=$LIGHT0
export GUM_INPUT_BACKGROUND=$DARK2

export GUM_SPINNER_FOREGROUND=$BRIGHT_AQUA
export GUM_SPINNER_BACKGROUND=$DARK0
export GUM_SPINNER_FOREGROUND=$BRIGHT_AQUA
export GUM_SPINNER_BACKGROUND=$DARK0

export GUM_STYLE_BORDER=$BRIGHT_ORANGE
export GUM_STYLE_FOREGROUND=$LIGHT0
export GUM_STYLE_BACKGROUND=$DARK3
