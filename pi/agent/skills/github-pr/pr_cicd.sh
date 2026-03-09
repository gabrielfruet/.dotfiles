#!/bin/bash
# Fetch CI/CD workflow runs for a PR

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

# Get the head SHA for this PR
HEAD_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUM" | \
  jq -r '.head.sha')

if [ -z "$HEAD_SHA" ]; then
  echo "Error: Could not get PR head SHA"
  exit 1
fi

# Get workflow runs for this commit
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/actions/runs?head_sha=$HEAD_SHA" | \
  jq '.workflow_runs[:10] | .[] | {name: .name, status: .status, conclusion: .conclusion, html_url: .html_url}'
