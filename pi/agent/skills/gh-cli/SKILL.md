---
name: gh-cli
description: Use when working with GitHub from the command line with gh: auth, repositories, issues/PRs, Actions, releases, API requests, aliases, and automation.
---

# gh-cli

Use gh for GitHub CLI tasks. Prefer JSON + jq for scripted output.

## Rules
- Check auth first: `gh auth status`
- Use `gh <group> --help` when unsure; do not memorize long option lists
- Prefer `--json`, `--jq`, `--template`, and `--paginate` for automation
- Use `gh pr ...` for PR work; this skill replaces the separate `github-pr` helper
- Scope cross-repo work with `--repo owner/name`

## Common commands
```bash
gh auth login
gh auth status
gh repo view --web
gh repo clone owner/repo
gh issue list
gh pr view 123 --web
gh pr checkout 123
gh run list
gh run view <run-id> --log
gh release list
gh api /user --jq '.login'
gh alias set prview 'pr view --web'
gh completion -s zsh
```
