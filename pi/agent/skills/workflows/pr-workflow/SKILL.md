---
name: pr-workflow
description: Use when opening a PR and driving it to green CI — push the branch, write a high-level PR description, watch checks, fix failures, and keep looping until green; also use when an already-open PR gets new commits, or when addressing review comments from humans or bots (CodeRabbit, Codex, Copilot), and when reviewing someone else's PR or branch.
---

# PR Workflow

## Loop
1. Ensure the work is committed on a feature branch (never push directly to
   main/master). Use the `git-workflow` skill for commit hygiene.
2. Push: `git push -u origin <branch>` (or `git push` if already tracking).
3. Check for an existing PR on this branch:
   `gh pr view <branch> --json number,url,body,state`
   - None open → spawn a subagent to draft the body. It loads
     `write-pr-description` and `human-voice` itself, and works from
     `git diff` and `git log` alone. Required, not a suggestion. Then create
     the PR with what it returns (see Description below).
   - Draft it yourself only when no subagent is available. Your context holds
     the whole implementation — every rejected approach, every measurement you
     took to get here — and a description written from it inherits all of that.
     The subagent's ignorance is the feature.
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
5. If a check is red, diagnose before fixing — don't guess at a code change:
   - Find the real failure: `gh run view <run-id> --log-failed`
   - Reproduce locally with a targeted test command for just the failing
     suite/file (whatever the project's runner is — vitest, pytest, etc.),
     not the full suite.
     - Fails locally too → real issue. Confirm scope with
       `git diff <base>...HEAD -- <path>` before touching anything, then fix
       the root cause in the code — don't skip/disable the check. Commit,
       push, go back to step 4.
     - Passes locally, fails only on CI → a CI-environment difference (stale
       cache, missing env var, dependency drift), not a code bug.
       Investigate the CI config/environment, not the source.
   - If the failure looks disconnected from the diff, rerun once instead of
     pushing a no-op: `gh run rerun <run-id> --failed`. If the parent
     workflow run is still in progress, wait for it to finish first (via
     `--watch`, not a manual sleep) — a run can't be rerun while active.
     - Passes on rerun → it was flaky. Don't just move on: consider opening
       a GitHub issue documenting it (repro steps, run link, recurrence) so
       it's tracked — draft it with `human-voice`, `gh-issue` channel. Ask the user
       first if the flake isn't clearly this PR's to report.
     - Still red after both checks (fails locally and fails again on rerun,
       diff doesn't touch it) → propose a minimal, separately-committed fix
       and wait for explicit user approval before applying it. Keep it as
       its own commit, not folded into the PR's main change, so it stays
       easy to drop or revert.
   - If the fix changed the PR's actual goal/approach (not just a bugfix),
     update the title and description (see below).
6. All checks green → done. Report the PR URL.
7. Asked to shorten, redo or re-scope the description → new subagent, same
   brief, current diff. Don't edit the prose in place. Trimming by hand keeps
   the altitude of the draft it came from, and by that point your context is
   dirtier than when you started.

## Title & Description
- Draft the body by running the `write-pr-description` skill in a subagent — it
  reads the diff and commits and produces a goal-first structured description.
  The rules below still govern the result.
- Write a high-level summary of *what the PR is trying to accomplish* — the
  goal/approach, not a changelog of every commit or CI fix. The diff already
  shows what changed.
- The title makes the same claim as the description, just compressed to one
  line — if the description names the approach (e.g. "sort coords" vs "skip
  degenerate boxes"), the title must match it. A stale title that names the
  old approach is misleading even if the body is accurate.
- Apply `human-voice`, `pr-description` channel: sound human, concise and decisive, and
  scope-honest (call out anything that belongs in a follow-up rather than
  smuggling it in).
- Never include internal/private links or references anywhere in the PR —
  not just the description body, but the title, and any commit messages you
  write for it too. This covers Notion docs, Linear ticket links or bare
  ticket IDs (`TRN-1234`), Slack thread/message links, or any other tool only
  teammates can open. This applies regardless of whether the repo is public
  or private — internal tools get reorganized, renamed, or lose access over
  time, so these links rot even for the team. Describe the "why" in plain
  prose instead, or link a public GitHub issue if one exists. If a ticket ID
  slips into a title or commit message anyway, fix it before calling the PR
  done: `gh pr edit <number> --title "..."` for the title; for commits already
  pushed, amend/reword and force-push the branch (safe pre-review, on your own
  feature branch).
- Check for `.github/pull_request_template.md` and use it if present.
- Create with `gh pr create --title "..." --body-file <file>` (avoids
  literal `\n` issues with inline `--body`).
- Update an existing PR with `gh pr edit <number> --title "..." --body-file <file>`.
- Only rewrite the title/description when the PR's *purpose or approach*
  changes (new goal, dropped goal, different implementation) — not for
  routine CI fixes, typos, or review nitpicks. When it does change, update
  both together — a title that still names the old approach is a common miss.

## Reviewing a PR or branch
Before reading a line of the diff, get current. A review against a stale base
reports code the author never touched and misses what they did.

1. `git fetch --all --prune`. Always, not conditional on the working tree
   looking clean.
2. Given a PR number, read the PR: `gh pr view <n>`, `gh pr diff <n>`. A number
   is not an invitation to guess at local refs.
3. Working from local refs instead, name the base and check it is not behind:

   ```bash
   git rev-list --count HEAD..origin/<base>
   ```

   Non-zero means your local base is stale. Range against `origin/<base>`.
4. State the resolved base commit in the review itself —
   `origin/master@a1b2c3d...HEAD`, not `master...HEAD`. A range without a commit
   is not a scope statement.

`git rev-parse --abbrev-ref @{upstream}` failing means the branch has no tracking
ref. That is a reason to fetch and name the base by hand, not a reason to fall
back to whatever the local copy happens to be.

## Review comments
Bot reviewers read the whole file, not your diff. A comment landing on a line
is not evidence that line is yours.

- Before acting on any comment, check whether this PR introduced the code it
  flags: `git diff <base>...HEAD -- <path>`. Already on the base branch → out
  of scope. Leave it.
- Refactor suggestions on pre-existing code ("split this into helpers",
  "extract a function") are the common trap. Folding one in makes the diff
  bigger than the change it supports, and a human reviewer will ask for it
  back out.
- Act on a bot comment when it names a real defect in code this PR introduced
  or broke.
- If the out-of-scope work looks worth doing, it goes in a follow-up PR —
  never this one. Ask the user first; never open one unprompted. If they pass,
  leave a TODO or drop it.
- Human comments outrank bot ones. When a human says a change is unnecessary,
  drop it — don't defend it.
- To undo a whole commit a reviewer rejected: `git revert --no-commit <sha>`,
  then commit with the review as the stated reason. Cleaner than unwinding the
  diff by hand.

## Rules
- Addressing review feedback must never grow the PR past its stated purpose.
  Out-of-scope work becomes a follow-up PR, and only after the user confirms.
- For commit-by-commit hygiene (staging, diff review, message format), defer
  to the `git-workflow` skill.
- For `gh` mechanics (auth, JSON output, inline vs review comments), defer to
  the `gh-cli` skill.
- For drafting the description body from the diff/commits, always run the
  `write-pr-description` skill, in a subagent.
- For PR description tone/detail/scope, defer to `human-voice`:
  `references/channels/pr-description.md`. For review comments you write and
  replies you post, `pr-review-comment.md` and `pr-review-reply.md`.
- Treat "watch CI" as blocking on the *result*: never report done before
  `gh pr checks` shows every check green — but the watch itself can run in
  the background if the tool supports it, rather than tying up the session.
- If new commits land on an already-open PR (yours or requested by the user),
  re-enter the loop at step 4 (watch CI) — and only touch the title/description
  if the PR's intent actually shifted.
