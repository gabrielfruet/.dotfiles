---
name: write-pr-description
description: Use to draft a PR description and title from the branch's diff and commits — analyze the changes, group them by area, and produce a goal-first structured Markdown body a reviewer can grasp in under a minute. Invoked by pr-workflow, or directly when asked to "write/generate/describe a PR".
---

# Write PR Description

Turn a branch's diff + commits into a reviewer-ready description. The diff already
shows *what* changed; your job is to state *why*, and at an altitude a reviewer can
grasp in under a minute.

## Gather

Run this in a subagent when one is available. The steps below are the *whole*
input — if you already know why the change was made without reading `git log`,
you are the wrong context to write the description, and it shows up as detail no
reviewer asked for.

1. Find the base: `git merge-base HEAD origin/main` (or the PR's actual base branch).
2. Read the changes: `git diff <base>...HEAD`
3. Read the intent: `git log <base>..HEAD` (full bodies, not `--oneline` — commit
   messages usually carry the "why" the diff can't show).
4. If `.github/pull_request_template.md` exists, fill *that* structure instead of
   the one below.

## Draft
Lead with the goal, then group the substance. Skip any section that adds no signal —
a short PR is one summary line, not an empty template.

- **Summary** — 1-3 sentences: what this PR accomplishes and the approach taken.
  Not a commit-by-commit changelog; the diff is the changelog.
- **Changes** — bullets grouped by area (e.g. `api/`, `tests/`, config), not per
  commit. One line each, describing intent, not mechanics.
- **Breaking changes** — only when a public API, config key, or CLI flag changed.
  Name old→new and the migration.
- **Testing** — how it was verified (commands run, cases covered). Omit if trivial.

## Length
Description length tracks diff size. A one-file config change gets a paragraph and
a testing line; a new subsystem earns the full template. The ceiling is 200 words
and 20 lines, declared in `human-voice`'s `references/channels/pr-description.md`
and enforced by its cut pass.

## Title
One line making the same claim as the Summary — name the approach, not the ticket ID.

## Rules
- Altitude over completeness: a reviewer reads the summary, not every bullet. If the
  approach shifts later, the title and summary must shift together.
- Apply `human-voice` to the final text, `pr-description` channel — terse,
  decisive, scope-honest.
- Never include internal/private links (Notion, Linear IDs like `TRN-1234`, Slack).
  Explain the "why" in prose, or link a public GitHub issue.
- Write the body to a file and hand off — `pr-workflow` owns `gh pr create/edit`
  and the CI loop; this skill only produces the text.
