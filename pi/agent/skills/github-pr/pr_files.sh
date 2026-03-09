#!/bin/bash
# Fetch PR file changes

if [ -z "$1" ]; then
  echo "Usage: $0 <PR_URL>"
  exit 1
fi

PR_URL="$1"

# Extract owner, repo, PR number from URL
if [[ $PR_URL =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
  PR_NUM="${BASH_REMATCH[3]}"
else
  echo "Error: Invalid PR URL"
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN not set"
  exit 1
fi

curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUM/files"
