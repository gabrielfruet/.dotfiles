---
name: task-memory
description: Use when the user starts, resumes, switches, saves, or recalls a named task or ongoing work across sessions (e.g. "remember this", "continue X", "what was I doing on Y", "track this task").
---

# Task Memory

Curated, cross-session context for named tasks. The `task-memory` extension stores one markdown file
per task at `~/.pi/agent/memory/<slug>.md`, keeps a per-directory active set, auto-restores it on startup,
and injects each active task as a `[TASK MEMORY: <name>]` block. Several tasks can be active at once.

## Recording (do this automatically, no need to ask)
- Use the `task_memory` tool, not raw file writes.
- `activate(name)` when the user starts or names work to track in this directory.
- `update(name, content)` at **milestones**, not after every operation.
- Overwrite with the full curated body each time. Keep it SMALL — never paste transcript or long logs.

### When to update (calibrate the cadence — do NOT refresh every step)
A milestone = a completed logical unit of work, a real decision, a new blocking fact, a
session end/handoff, or an explicit "remember/save". Update at milestones only.

- **Skip the update** if the last one was only a few turns ago AND nothing fundamentally
  changed (no new decision, no milestone completed, no new gotcha/blocker). Advancing one
  TODO notch, editing one more file, or running one more command is NOT a milestone.
- **Coalesce**: when about to update and you already updated a few turns back on the same
  arc, wait until the arc completes and update once.
- **Rule of thumb**: for a typical task aim for ~3–6 updates across its whole lifetime
  (start, 1–2 mid-milestones, end) — not one per sub-step.
- Only `show`/`list` when actually resuming or unsure; don't probe every turn.

## File template
```markdown
# Task: <name>
Updated: <YYYY-MM-DD>

## Goal
<1-3 lines: what we're trying to achieve>

## Status / Progress
- <what's done>

## Next steps
- <what's next>

## Key facts & decisions
- <commands, paths, metrics, gotchas worth keeping>
```

## Resuming
- The active tasks are already injected as `[TASK MEMORY: ...]` — trust them; don't re-ask the user.
- `task_memory show` (or `/recall`) to print the current active task(s).
- `task_memory list` (or `/tasks`) to see all known tasks.
- **Stale re-injection after rescoping**: if the user changed scope mid-session, a stale
  planning-phase task can keep getting re-injected while a maintained task already reflects
  the new authoritative state. Trust the **maintained** task (the one you've been
  `update`-ing); treat the stale block as noise and do NOT re-flag it every turn. If the
  stale task is still active in the directory, `deactivate` it once and overwrite the
  authoritative task so future injections match reality.
- **Duplicate-task-file stale injection** (related variant): if the same work has been
  tracked under multiple names across sessions (e.g. `ecvit-lt-detr-benchmarks`,
  `ltdetrv2-m-l-x`, `lt-detr-v2-default-config-benchmarks-ltdetrv2-m-l-x` all for one
  ticket), they may all be active in the directory's set at once. The system injects
  only ONE of them (often the oldest or first-activated), so `task_memory update` against
  the most-recent file won't change what you see in the `[TASK MEMORY: ...]` block.
  Symptom: `task_memory show <canonical-name>` shows your updated content but the injected
  block is stale, and `task_memory list` shows multiple tasks marked active with
  overlapping content. Fix: `task_memory list` → `task_memory deactivate <stale>` on each
  duplicate → `task_memory activate <canonical>` on the one you want injected. Then
  `update` it to reflect current state. The injection only refreshes on session resume,
  so a new session is needed to see the updated block.

## Rescoping
When the user changes scope mid-session (e.g. "for now just X, not Y", "docs in a
follow-up PR", "no compile call, raise instead"), do two things in one shot:

1. `update` the active task with the new authoritative state (Goal, Status, Key
   facts & decisions) — clearly mark the old state as superseded (e.g. "Earlier
   planning-phase memory mentioning Y is STALE & superseded").
2. `deactivate` any stale sibling tasks that reflect the old scope (e.g. an
   original "Plan integration" task that covered both pretrain and fine-tune when
   the user rescoped to fine-tune only).

The goal is that the next `[TASK MEMORY: ...]` injection matches what you're
actually doing. Do not paste the old scope into the maintained task as a
"changelog" — keep the maintained task clean and authoritative; note superseded
state in a single short line.

## Proactive deactivation (when YOU notice staleness, not the user)

If you describe an active task memory as "paused", "unrelated", "stale", or "different
scope" in your response — and you said the same thing in the previous turn — call
`task_memory deactivate <name>` at the end of this turn. Don't wait for the user to tell
you to clean up.

**Heuristic:** 2 consecutive turns describing the same staleness → deactivate.
**Done tasks count as stale.** Once the body says "Status: DONE", deactivate at session end
or when switching to unrelated work.
**Cost of inaction:** every subsequent turn re-injects the stale block and you re-acknowledge
it. One `deactivate` call now is cheaper than N "paused/unrelated" disclaimers.

**Failure mode this prevents:** "X is paused/unrelated" in turns 1, 2, 3, 4, then the user
finally says "why don't you just deactivate it?". That whole arc was avoidable.

## Notes
- Task files are global (shared across directories); only the active set is per-directory.
- User commands: `/task <name>` (activate here), `/untask <name>` (drop here), `/forget <name>` (archive).
