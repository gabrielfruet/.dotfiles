#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

bash -n "$ROOT_DIR/lib/github_pr.sh"
bash -n "$ROOT_DIR/pr.sh"
bash -n "$SCRIPT_DIR/parse_pr_url.sh"

"$SCRIPT_DIR/parse_pr_url.sh"

echo "smoke: ok"
