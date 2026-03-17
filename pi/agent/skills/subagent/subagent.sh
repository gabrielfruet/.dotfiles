#!/bin/bash
# Spawn a pi subagent - usage: subagent.sh "prompt" [--model x] [--thinking x] [--cwd x]

MODEL_FLAG=""
THINKING_FLAG=""
CWD_FLAG=""
PROMPT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model) MODEL_FLAG="--model $2"; shift 2 ;;
        --thinking) THINKING_FLAG="--thinking $2"; shift 2 ;;
        --cwd) CWD_FLAG="$2"; shift 2 ;;
        *) PROMPT="$1"; shift ;;
    esac
done

[[ -z "$PROMPT" ]] && { echo "Usage: $0 <prompt> [--model x] [--thinking x] [--cwd x]" >&2; exit 1; }

# Change to target directory to auto-discover local AGENTS.md
if [[ -n "$CWD_FLAG" ]]; then
    cd "$CWD_FLAG" || { echo "Error: Cannot cd to $CWD_FLAG" >&2; exit 1; }
fi

pi --print --no-session $MODEL_FLAG $THINKING_FLAG "$PROMPT"
