---
name: pr-workflow
description: Use when opening a PR and driving it to green CI — push the branch, write a high-level PR description, watch checks, fix failures, and keep looping until green; also use when an already-open PR gets new commits.
---

# PR Workflow

## Loop
1. Ensure the work is committed on a feature branch (never push directly to
   main/master). Use the `git-workflow` skill for commit hygiene.
2. Push: `git push -u origin <branch>` (or `git push` if already tracking).
3. Check for an existing PR on this branch:
   `gh pr view <branch> --json number,url,body,state`
   - None open → create one (see Description below).
   - Already open → reuse it, don't create a duplicate.
4. Watch CI: `gh pr checks <number-or-branch> --watch`
   - This blocks until every check reaches a final state, polling on its own —
     never wrap it in a manual `sleep`/poll loop, that's what `--watch` is for.
   - Avoid `--fail-fast` here: it returns the instant *any single* check goes
     red, even while others are still pending/running, which tempts you into
     acting (e.g. deciding to rerun) before the full picture is in. Let
     `--watch` run to completion so you see the final state of every check at
     once.
   - If backgrounding is available, run this in the background instead of
     blocking the session — keep working (or wait idle) and pick back up
     when it reports back.
5. If a check is red:
   - Find the real failure: `gh run view <run-id> --log-failed`
   - Fix the root cause in the code — don't skip/disable the check.
   - Commit, push.
   - If the fix changed the PR's actual goal/approach (not just a bugfix),
     update the title and description (see below).
   - Go back to step 4.
   - If failure looks like pure infra flake (not caused by the diff), rerun
     instead of pushing a no-op: `gh run rerun <run-id> --failed`. If the
     parent workflow run is still in progress, wait for it to finish first
     (via `--watch`, not a manual sleep) — a run can't be rerun while active.
6. All checks green → done. Report the PR URL.

## Title & Description
- Write a high-level summary of *what the PR is trying to accomplish* — the
  goal/approach, not a changelog of every commit or CI fix. The diff already
  shows what changed.
- The title makes the same claim as the description, just compressed to one
  line — if the description names the approach (e.g. "sort coords" vs "skip
  degenerate boxes"), the title must match it. A stale title that names the
  old approach is misleading even if the body is accurate.
- Apply the `human-voice` skill: sound human, concise and decisive, and
  scope-honest (call out anything that belongs in a follow-up rather than
  smuggling it in).
- Never include internal/private links in a PR description — Notion docs,
  Linear ticket links or bare ticket IDs (`TRN-1234`), Slack thread/message
  links, or any other tool only teammates can open. This applies regardless
  of whether the repo is public or private — internal tools get reorganized,
  renamed, or lose access over time, so these links rot even for the team.
  Describe the "why" in plain prose instead, or link a public GitHub issue if
  one exists.
- Check for `.github/pull_request_template.md` and use it if present.
- Create with `gh pr create --title "..." --body-file <file>` (avoids
  literal `\n` issues with inline `--body`).
- Update an existing PR with `gh pr edit <number> --title "..." --body-file <file>`.
- Only rewrite the title/description when the PR's *purpose or approach*
  changes (new goal, dropped goal, different implementation) — not for
  routine CI fixes, typos, or review nitpicks. When it does change, update
  both together — a title that still names the old approach is a common miss.

## Rules
- For commit-by-commit hygiene (staging, diff review, message format), defer
  to the `git-workflow` skill.
- For `gh` mechanics (auth, JSON output, inline vs review comments), defer to
  the `gh-cli` skill.
- For PR description tone/detail/scope, defer to the `human-voice` skill.
- Treat "watch CI" as blocking on the *result*: never report done before
  `gh pr checks` shows every check green — but the watch itself can run in
  the background if the tool supports it, rather than tying up the session.
- If new commits land on an already-open PR (yours or requested by the user),
  re-enter the loop at step 4 (watch CI) — and only touch the title/description
  if the PR's intent actually shifted.
