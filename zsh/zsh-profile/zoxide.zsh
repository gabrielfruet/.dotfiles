#!/bin/env zsh
# zoxide: smart directory jumper.
#   z <keywords>   jump to a frecent directory
#   zi <keywords>  interactive pick
# `cd` stays the shell builtin so scripts and agent shells navigate literally.
export _ZO_DOCTOR=0
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
