---
name: ship-stack
description: Use when asked to plan and ship a change as a PR stack, split work so PRs pass Fast Track, or take a lightly-studio feature from brainstorm to merged PRs.
---

# Ship a stack

Gabriel wants to make as few decisions as possible. Take every easy decision
yourself. Bring him only the routing calls and the real trade-offs, each as one
line with your recommendation. Ask in plain numbered text, never question
boxes.

## Steps

1. **Brainstorm.** Run `superpowers:brainstorming`. When the scope is fuzzy,
   test the real workflow in the GUI first (`run` skill or the browser pane)
   and brainstorm from the bugs you saw. Done: a spec Gabriel approved.
2. **Propose the stack.** Load `pr-workflow` (`references/scope.md`). Each PR
   has one purpose and is sized to pass the Fast Track bot (rules below).
   Done: a table with PR, purpose, estimated added lines, route.
3. **Route each PR.** Mark it *review* when it changes UI, turns behavior into
   something new, or carries high risk to the end user or the code. Mark the
   rest *Fast Track*. Give each *review* PR a one-line concern. Gabriel
   decides the flagged ones. Done: every PR has a route he accepted.
4. **Implement.** `superpowers:writing-plans`, then subagent-driven or inline
   execution, one branch per PR, each based on its parent. A question that
   changes what users see goes to Gabriel the moment it comes up. Build
   everything it does not block; the part it blocks waits for his answer.
5. **Self-review.** Run `superpowers:requesting-code-review` on each PR and
   fix with `superpowers:receiving-code-review` until it comes back clean. Run the guardrails locally
   (below). Done: every PR clean and green on guardrails.
6. **Report.** One short message: what is ready, the decisions only Gabriel
   can make, nothing else.
7. **Ship.** Re-check each finished PR's risk; a PR that grew risky moves to
   *review*. Commit and push only when Gabriel says so. Open PRs with
   `pr-workflow`. Fast Track PRs need no ask. For *review* PRs, follow the
   `lightly` skill's `references/studio-review.md`: show the exact `/review`
   and Slack text and wait for his yes before sending.

## Fast Track rules

The source of truth is `fast_track/README.md` and `fast_track/src/guardrails/`
in lightly-studio. Re-read them when a limit matters; these values can drift.
As of 2026-11:

- **Size** (`diff-size.ts`): at most 215 added lines, tests included. Deleted
  lines do not count. Lockfiles, `lightly_studio/tests/benchmarks/` and
  `vendor/` are excluded.
- **Complexity**: frontend ESLint `complexity` max 10
  (`lightly_studio_view/eslint.complexity.config.js`); backend ruff `C901`.
- **Coverage**: at least 90% of added lines per changed source file. Frontend
  counts `.svelte`. Backend skips tests, `__init__.py` and migrations.
- Drafts are not judged. The `no-fast-track` label opts a PR out.

Check locally after committing:

```bash
cd fast_track && BASE_REF=<parent-branch> make run-guardrails
```
