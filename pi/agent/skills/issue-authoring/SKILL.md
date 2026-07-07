---
name: issue-authoring
description: Use when creating, writing, or drafting a GitHub issue. Covers tone, conciseness, detail, scope, and audience-fit — not investigation or gh mechanics.
---

# Issue Authoring

Guidelines for writing a good GitHub issue. Assumes investigation is done
(use codebase-exploration / gh-cli for that) and mechanics are handled
(gh-cli covers `gh issue create --body-file`).

## Principles (always apply)

1. **Sound human.** Write prose with voice, not stacked headers of corporate
   hedging. Read it aloud — if it sounds bot-generated, rewrite. "We've decided
   to remove the integration" beats "This issue proposes the removal of...".

2. **Concise and decisive.** State what matters; cut the rest. Don't over-cite
   or over-justify — one telling detail beats a table of every supporting fact.
   If a reader needs the full evidence, link it; don't reproduce it.

3. **Match detail to purpose.** A chore wants action (checklist). A discussion
   or spike wants findings. Don't dump investigation output into a task that
   wants a handoff — and don't force a checklist onto an open question.

4. **Be scope-honest.** If something looks in-scope but belongs elsewhere, say
   so and defer it with a link. Scope creep turns a `good first issue` into a
   trap for the contributor who picks it up.

## Audience

State the audience before writing — it sets tone, assumed context, detail, and
labels. Match the row; let it steer the draft.

| Audience | Tone | Detail | Labels |
|---|---|---|---|
| Contributor pickup | Direct, actionable; assume less context | Task as checklist; flag maintainer-only steps; defer out-of-scope with links | `help wanted`, `good first issue` (only if truly scoped & trap-free) |
| Maintainer sync | Terse; assume shared context | Just the decision/change; skip background | usually none |
| Bug triage | Neutral, reproducible | Description + repro + expected/actual + env | `bug` |
| Discussion / spike | Open, exploratory | Findings + open questions; no forced checklist | `enhancement` / `feature request` |

## Self-check (run over the draft before creating)

1. **Human?** Read it aloud. Bot-sounding? Rewrite.
2. **Earns its place?** Any over-citing or over-justifying to cut?
3. **Detail matches purpose?** Action for chores, findings for discussions?
4. **Scope-honest?** Anything smuggled in that belongs in another issue? Link & defer.
5. **Right audience default?** Tone and labels match who will read it?
6. **Labels honest?** `good first issue` only if genuinely scoped and trap-free.
