#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/github_pr.sh
source "$SCRIPT_DIR/../lib/github_pr.sh"

assert_parse() {
  local url="$1"
  local owner="$2"
  local repo="$3"
  local number="$4"

  parse_pr_url "$url"

  [[ "$GITHUB_PR_OWNER" == "$owner" ]]
  [[ "$GITHUB_PR_REPO" == "$repo" ]]
  [[ "$GITHUB_PR_NUMBER" == "$number" ]]
}

assert_reject() {
  local url="$1"

  if parse_pr_url "$url"; then
    echo "unexpected success: $url" >&2
    exit 1
  fi
}

assert_parse "https://github.com/owner/repo/pull/123" "owner" "repo" "123"
assert_parse "https://github.com/owner/repo/pull/123.diff" "owner" "repo" "123"
assert_parse "https://github.com/owner/repo/pull/123/files" "owner" "repo" "123"
assert_reject "https://github.com/owner/repo/issues/123"
assert_reject "not-a-url"

echo "parse_pr_url: ok"
