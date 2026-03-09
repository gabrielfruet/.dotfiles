---
name: github-pr
description: Fetch GitHub PR info, CI/CD status, and file changes. Requires GITHUB_TOKEN env var.
---

# GitHub PR Tool

## Setup

Set your GitHub token before running pi:

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

Get a token at: https://github.com/settings/tokens

## Usage

```bash
./pr_info.sh <PR_URL>
./pr_cicd.sh <PR_URL>
./pr_files.sh <PR_URL>
```

## Examples

- `https://github.com/owner/repo/pull/123`
- `https://github.com/owner/repo/pull/123.diff`
