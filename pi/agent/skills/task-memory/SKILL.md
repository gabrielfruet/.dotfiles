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

## Notes
- Task files are global (shared across directories); only the active set is per-directory.
- User commands: `/task <name>` (activate here), `/untask <name>` (drop here), `/forget <name>` (archive).
