---
name: issue-authoring
description: Use when creating, writing, or drafting a GitHub issue. Covers tone, conciseness, detail, scope, and audience-fit — not investigation or gh mechanics.
---

# Issue Authoring

Guidelines for writing a good GitHub issue. Assumes investigation is done
(use codebase-exploration / gh-cli for that) and mechanics are handled
(gh-cli covers `gh issue create --body-file`).

## Principles (always apply)

For general prose style (sound human, concise & decisive, scope-honest),
defer to the `human-voice` skill. On top of that, for issues specifically:

1. **Match detail to purpose.** A chore wants action (checklist). A discussion
   or spike wants findings. Don't dump investigation output into a task that
   wants a handoff — and don't force a checklist onto an open question.

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

Run the `human-voice` self-check first, then these issue-specific checks:

1. **Detail matches purpose?** Action for chores, findings for discussions?
2. **Right audience default?** Tone and labels match who will read it?
3. **Labels honest?** `good first issue` only if genuinely scoped and trap-free.
