---
name: github-pr
description: Fetch GitHub PR info, CI/CD status, file changes, and failure summaries with gh.
---

# GitHub PR Tool

Prefer the single entrypoint:

```bash
./pr.sh info <PR_URL>
./pr.sh cicd <PR_URL>
./pr.sh files <PR_URL>
./pr.sh errors <PR_URL>
./pr.sh mine [state]
```

Options:
- `--json` for stable agent-friendly output
- `--logs` on `errors` for failed-step log summaries

Requirements:
- `gh` CLI installed and authenticated
- `jq` installed

Examples:
- `./pr.sh info https://github.com/owner/repo/pull/123 --json`
- `./pr.sh errors https://github.com/owner/repo/pull/123 --logs`
- `./pr.sh mine all --json`
