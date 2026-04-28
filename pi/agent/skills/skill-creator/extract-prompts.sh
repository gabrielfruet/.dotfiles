#!/bin/bash
# Extracts user prompts from session files

jq -r 'select(.type=="message" and .message.role=="user") | .message.content[0].text' "$@"
