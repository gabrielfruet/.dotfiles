---
name: gh-cli
description: "Use when working with GitHub from the command line with gh for auth, repo/issue/PR triage, reviews, Actions, releases, API requests, aliases, and automation."
---

# gh-cli

Use gh for GitHub tasks. Prefer JSON + jq for scripted output.

## Rules
- Check auth first: `gh auth status`.
- Use `gh <group> --help` when unsure.
- Prefer `--json`, `--jq`, `--template`, and `--paginate`.
- Use `gh pr ...` for PR work.
- For new PRs, push the branch first; `gh pr create` needs a remote branch. Use `--head`
  only for an already-pushed branch.
- For multiline PR bodies, prefer `--body-file` (or a heredoc/file) instead of inline `--body` to avoid literal `\n` in GitHub.
- For existing PRs, use `gh pr view <branch-or-number> --json isDraft,number,title,url,body` and `gh pr edit <number> --body-file <file>`.
- Scope cross-repo work with `--repo owner/name`.

## Triage recipes
```bash
gh repo view --json nameWithOwner,url -q '.nameWithOwner + " " + .url'
gh issue list --state all --limit 20 --json number,title,state,labels,author
gh pr list --state open --limit 20 --json number,title,author,updatedAt
gh pr list --state merged --limit 20 --json number,title,mergedAt,author
```

## Review inspection
```bash
gh pr view 123 --json reviews,comments,files
```
- Group comments by reviewer and ignore empty/bot noise when summarizing.
- If review data looks incomplete, fall back to `gh api repos/<owner>/<repo>/pulls/<num>/reviews`.

## Common commands
```bash
gh auth login
gh auth status
gh repo clone owner/repo
gh pr view 123 --web
gh pr view <branch> --json isDraft,number,title,url,body
gh pr checkout 123
gh run list
gh run view <run-id> --log
gh release list
gh api /user --jq '.login'
gh alias set prview 'pr view --web'
gh completion -s zsh
```
