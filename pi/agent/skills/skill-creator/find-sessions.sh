#!/bin/bash
# Finds session files by scope

SCOPE="${1:-global}"
SESSIONS_DIR="$HOME/.dotfiles/pi/agent/sessions"

if [ "$SCOPE" = "local" ]; then
    # Current working directory encoded as path
    CWD_ENCODED=$(pwd | sed 's/\//-/g')
    find "$SESSIONS_DIR" -name "---${CWD_ENCODED}--*.jsonl" 2>/dev/null | sort
else
    find "$SESSIONS_DIR" -name "*.jsonl" 2>/dev/null | sort
fi
