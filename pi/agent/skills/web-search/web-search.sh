#!/usr/bin/env bash
# Web search using DuckDuckGo via ddgs CLI

QUERY="${1:-}"
MAX_RESULTS="${2:-5}"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 <query> [max_results]" >&2
    exit 1
fi

# Use fixed temp path instead of mktemp (ddgs -o has issues with variable paths)
TEMP_FILE="/tmp/ddgs_results_$$.json"

cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

ddgs text -q "$QUERY" -m "$MAX_RESULTS" -b duckduckgo -o "$TEMP_FILE" >/dev/null 2>&1
cat "$TEMP_FILE"
