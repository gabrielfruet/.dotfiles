#!/bin/bash

if [[ -n "${GITHUB_PR_LIB_LOADED:-}" ]]; then
  return 0
fi
GITHUB_PR_LIB_LOADED=1

GITHUB_PR_OWNER=""
GITHUB_PR_REPO=""
GITHUB_PR_NUMBER=""

fail() {
  echo "Error: $*" >&2
  exit 1
}

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    fail "$name not found"
  fi
}

require_gh_auth() {
  require_command gh

  if ! gh auth status >/dev/null 2>&1; then
    fail "Not authenticated with gh. Run 'gh auth login' first."
  fi
}

require_jq() {
  require_command jq
}

parse_pr_url() {
  local pr_url="$1"

  if [[ "$pr_url" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    GITHUB_PR_OWNER="${BASH_REMATCH[1]}"
    GITHUB_PR_REPO="${BASH_REMATCH[2]}"
    GITHUB_PR_NUMBER="${BASH_REMATCH[3]}"
    return 0
  fi

  return 1
}

repo_ref() {
  echo "$GITHUB_PR_OWNER/$GITHUB_PR_REPO"
}

pr_endpoint() {
  echo "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/pulls/$GITHUB_PR_NUMBER"
}

get_pr_json() {
  gh api "$(pr_endpoint)"
}

get_pr_head_sha() {
  gh api "$(pr_endpoint)" --jq '.head.sha'
}

empty_json_array() {
  echo '[]'
}

json_array_from_file() {
  local path="$1"

  if [[ -s "$path" ]]; then
    jq -s '.' "$path"
  else
    empty_json_array
  fi
}
