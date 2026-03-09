#!/bin/bash
# Wrapper script for subagent
# Delegates to the node implementation

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$SCRIPT_DIR/subagent.js" "$@"
