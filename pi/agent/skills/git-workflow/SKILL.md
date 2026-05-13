---
name: git-workflow
description: Git commit workflow. Load when staging or committing. 
---

# Git Workflow

## Rules

- Never `git add -A`
- Show diff before every commit
- Separate commits by logical change
- Commit automatically after review
- If a commit hook rewrites files, re-run `git add` on the touched files before retrying the commit.
- If the task includes a PR description or plan, inspect `.github/pull_request_template.md` and any relevant files in `.github/`

## Commit Workflow

1. Run `git diff --staged`
2. Run `git diff`
3. Run `git status` and flag unrelated modified files
4. Identify logical changes
5. Stage intentionally (`git add <file>` or `git add -p`)
6. Run `git diff --staged` to verify
7. Commit with concise message (see below)
8. Repeat for remaining changes

## Commit Messages

- **Subject line**: max 72 characters
- **Format**: `type: description` (e.g., `feat: add mask function`)
- **No body/description** unless absolutely needed
- **No bullet points or paragraphs**
- Keep it scannable in `git log`

## Multiple Commits

If unrelated changes exist, create multiple commits:

```bash
git add <files-for-commit-1>
git commit -m "type: description"
git add <files-for-commit-2>
git commit -m "type: description"
```

## Undo

```bash
git reset HEAD~1       # undo last commit (keep changes)
git reset --soft HEAD~1 # undo last commit (keep staged)
```
