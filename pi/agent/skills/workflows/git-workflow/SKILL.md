---
name: git-workflow
description: Git commit workflow. Load when finishing any code-change task (after verification) to commit and push, or when explicitly staging/committing.
---

# Git Workflow

## Rules

- Never `git add -A`
- Show diff before every commit
- Separate commits by logical change
- Never invent a commit author identity. Before any `git commit`, read the
  author from git config (local first, then global):
  ```bash
  git config user.name; git config user.email
  ```
  If both are empty, prompt the user for their name and email and set them
  (prefer repo-local config: `git config user.name "..."` / `user.email "..."`)
  before committing. Never use placeholder identities like `pi <pi@local>`,
  `<agent> <agent@local>`, etc. — those end up in `git log` and on the PR.
- Commit automatically after review, then push the branch unless the user says not to.
- If a commit hook rewrites files, re-run `git add` on the touched files before retrying the commit.
- Before switching branches or popping a stash, check for untracked files that may conflict with tracked paths on the target branch; back them up first if needed.
- If the task includes a PR description or plan, inspect `.github/pull_request_template.md` and any relevant files in `.github/`

## Commit Workflow

1. Run `git diff --staged`
2. Run `git diff`
3. Run `git status` and flag unrelated modified files
4. Identify logical changes
5. Stage intentionally (`git add <file>` or `git add -p`)
6. Run `git diff --staged` to verify
7. Commit with concise message (see below)
8. Push the branch
9. If push is rejected with `fetch first`, run `git fetch` and `git rebase` onto the tracked branch, then retry
10. Repeat for remaining changes

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

## Rebase gotcha: `git rebase --continue` hangs in pi bash

If `EDITOR=nvim` (or any TTY-bound editor) is set in the environment,
`git rebase --continue` will spawn that editor to confirm the commit message
and **hang indefinitely** in pi's non-interactive bash tool — the tool reports
"Command aborted" after the shell timeout, and git is left in a half-finished
rebase state.

**Fix:** bypass the editor with `core.editor=true`:

```bash
git -c core.editor=true rebase --continue
```

Equivalent: `GIT_EDITOR=true git rebase --continue`.

Apply this whenever `--continue` / `--abort` / `--skip` appear to hang. The same
applies to other git operations that spawn an editor (interactive rebase,
`git commit` without `-m`, `git tag -a`, etc.).

## Fixing a PR's merge conflicts

For cross-fork PRs (`isCrossRepository: true`), `git push origin <branch>` does
NOT update the PR — it only creates a new branch on the base repo. To update the
PR, push to the contributor's fork:

```bash
gh pr view <N> --repo <org>/<repo> --json maintainerCanModify
# if maintainerCanModify: true:
git push git@github.com:<contributor>/<repo>.git <local>:<pr-branch>
```

In a `git merge`, `--ours` = current branch, `--theirs` = branch being merged in
(opposite of `git checkout`'s --ours/--theirs semantics in rebase).
