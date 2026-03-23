#!/usr/bin/env bash
set -euo pipefail

MODEL="meta-llama/llama-4-scout-17b-16e-instruct"
API_URL="https://api.groq.com/openai/v1/chat/completions"

usage() {
    cat <<EOF
Usage: $0 <image_path> [prompt]

Send an image to Groq VLM for analysis.

Arguments:
  image_path  Path to image file (required)
  prompt      Question/task for VLM (optional, reads from stdin if missing)

Environment:
  GROQ_API_KEY  API key for Groq

Example:
  $0 screenshot.png "What layout issues do you see?"
EOF
}

check_deps() {
    command -v curl >/dev/null || { echo "Error: curl not found" >&2; exit 1; }
    command -v jq >/dev/null || { echo "Error: jq not found" >&2; exit 1; }
    command -v base64 >/dev/null || { echo "Error: base64 not found" >&2; exit 1; }
}

check_api_key() {
    if [[ -z "${GROQ_API_KEY:-}" ]]; then
        echo "Error: GROQ_API_KEY not set" >&2
        exit 1
    fi
}

get_prompt() {
    local image_path="$1"
    shift

    if (($# > 0)); then
        printf '%s' "$*"
    elif ! [[ -t 0 ]]; then
        cat
    else
        printf 'Describe what you see in this image.'
    fi
}

get_mime_type() {
    local file="$1"
    case "${file##*.}" in
        png)  printf 'image/png' ;;
        jpg|jpeg) printf 'image/jpeg' ;;
        gif)  printf 'image/gif' ;;
        webp) printf 'image/webp' ;;
        *)    printf 'image/png' ;;
    esac
}

call_groq() {
    local image_path="$1"
    local prompt="$2"
    local mime_type
    local response
    local payload_file

    if [[ ! -f "$image_path" ]]; then
        echo "Error: file not found: $image_path" >&2
        exit 1
    fi

    mime_type="$(get_mime_type "$image_path")"
    payload_file="$(mktemp)"

    printf '{"model":"%s","messages":[{"role":"user","content":[{"type":"text","text":%s},{"type":"image_url","image_url":{"url":"data:%s;base64,%s"}}]}],"temperature":0.3}' \
        "$MODEL" \
        "$(printf '%s' "$prompt" | jq -Rs .)" \
        "$mime_type" \
        "$(base64 -w 0 "$image_path")" \
        > "$payload_file"

    response=$(curl -s "$API_URL" \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: application/json" \
        --max-time 60 \
        --data-binary "@$payload_file")

    rm -f "$payload_file"

    echo "$response" | jq -r '.choices[0].message.content // .error.message // empty'
}

main() {
    if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        usage
        exit 0
    fi

    check_deps
    check_api_key

    local image_path="$1"
    shift
    local prompt
    prompt="$(get_prompt "$image_path" "$@")"

    call_groq "$image_path" "$prompt"
}

main "$@"
