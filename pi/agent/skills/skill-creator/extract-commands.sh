#!/bin/bash
# Extracts bash commands from session files

jq -r 'select(.type=="message" and .message.role=="assistant") | .message.content[] | select(.type=="toolCall" and .name=="bash") | .arguments.command' "$@"