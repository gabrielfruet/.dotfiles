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

## Commit Workflow

1. Run `git diff --staged`
2. Run `git diff`
3. Identify logical changes
4. Stage intentionally (`git add <file>` or `git add -p`)
5. Run `git diff --staged` to verify
6. Commit with concise message (see below)
7. Repeat for remaining changes

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
