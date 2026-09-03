---
name: change-walkthrough
description: >-
  Use when the user wants to understand the blast radius of a change they intend
  to make, before touching code — "what breaks if I change X", "walk me through
  what this touches", "show me the ripple effects". Runs an interactive in-chat
  tour of the change surface: what changes, where (file:line), before→after per
  site, and downstream effects. Nothing is written to disk and no approval is
  captured. Not for deciding what to build (brainstorming), ordering or gating
  the work (plan-mode), or reviewing an existing PR's diff (pr-workflow).
---

# Change walkthrough

Walk the user through a change they have already decided to make: what changes,
where, before→after, and what it ripples into. Conversational and ephemeral —
the deliverable is a shared mental model, not a document.

The distinct value is the **presentation**, not the finding: blast-radius
ordering, a fixed shape per stop, and continuous orientation. Discovery is
delegated.

**Never** here: write to disk, edit code, run non-read-only commands, sequence
steps into a numbered plan, or capture approval. Those belong to `plan-mode`.

**Scale to blast radius.** A one-line or obvious edit needs no tour — say so and
skip. Reserve the tour for changes whose ripple is not obvious.

If the *what* is not decided yet, stop and route to `brainstorming`. If it is an
existing PR or diff to review, route to `pr-workflow`.

## 1. Get the surface

- Delegate discovery to `codebase-exploration` (read-only). Do not re-derive the
  sweep — that skill owns finding the touched files, config, and risks.
- When a ripple's origin is unclear, trace it with `codepath-debugging`.
- Classify each site safe-additive vs breaking. Additive-looking changes that
  still break are catalogued in `references/impact-traps.md`.

## 2. Order the stops

- Order by blast radius, never by file or commit order: entry point (orient) →
  data model / schema → architecture → business logic → cosmetics last.
- Open with a change map grouped by intent (not by file) as the table of contents.
- Bound the tour by number of stops, not diff size. Too many? Group the
  low-radius ones and summarize.

## 3. Narrate each stop

Fixed shape, every stop:

- **What** changed · **Where** (a real `file:line` the user can open) ·
  **Before→After** · **Effect** on behavior · **Risk** flag if any.

Zoom into the ~20% that carries the logic; summarize the rest. Ground every claim
in quoted code or a cited `file:line` — no "this might affect…".

## 4. Keep them oriented

- Show "stop N of M" and restate state as each one lands.
- Default to peer register — the user knows their own change. Explain, do not quiz.
- Only when the user is unfamiliar with the code, switch to the depth ladder and
  comprehension checks in `references/teaching-mode.md`. Never "does that make sense?".
- Route the prose through `human-voice`'s `ai-facing` channel, shaped by `i-have-adhd`.

## 5. Stay honest

- A suspicion is not a confirmed bug — flag it as a risk to check.
- Separate what the user stated from what you inferred. An empty section says "None".
- A tour is not a verification pass. Recommend a real review or a `plan-mode` pass
  to confirm the risks you flagged.

## Handoff

When the user has the picture and wants to act, they enter `plan-mode` for the
numbered steps and the approval gate. plan-mode may re-verify the surface — this
tour built understanding, it did not produce a plan artifact to hand over.
