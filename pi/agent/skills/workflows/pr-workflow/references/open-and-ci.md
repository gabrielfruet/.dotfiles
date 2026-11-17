# Opening a PR and watching CI

## Open

1. Work on a feature branch, never main. With a Linear issue, branch with
   `linear issue start <id>`, which keeps the ticket ID in the branch name and
   out of the PR.
2. Run the size check in `scope.md`.
3. Push, then check for an open PR: `gh pr view <branch> --json number,url,state`.
   When one is already open, reuse it.
4. None open: spawn a subagent to draft the title and body. It reads
   `pr-description.md`, loads `human-voice`, and works from `git diff` and
   `git log` alone. Your context holds every rejected approach, and a
   description written from it shows that. Draft it yourself only when no
   subagent is available.
5. Create with `gh pr create --title "..." --body-file <file>`. Add `--draft`
   for each PR of a stack (see `ask-review.md`).

## CI

- Watch in the background with `gh pr checks <n> --watch`, and report the PR URL
  right away. Block on green only when the user asks to wait.
- Never use `--fail-fast` or a manual sleep loop. `--watch` runs every check to
  its final state.
- When a check goes red, find the real failure before changing code. Never skip
  or disable a check.
- When a failure has nothing to do with the diff, rerun it once:
  `gh run rerun <id> --failed`. If it passes, consider a GitHub issue for the
  flake. Ask first when it isn't clearly this PR's to report.
- A fix outside the PR's scope is its own commit, applied only after the user
  approves.

## Update

- New commits on an open PR: push, then watch CI again.
- Rewrite the title and body only when the PR's goal or approach changes, and
  then both together.
- Asked to shorten or redo the description: spawn a new subagent with the
  current diff. Never trim the old prose by hand.
- Anything internal (ticket ID, customer, Notion or Slack link) in a pushed
  title or commit gets fixed before the PR counts as done.
