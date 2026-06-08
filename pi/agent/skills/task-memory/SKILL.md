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
- `update(name, content)` after meaningful progress, decisions, or on "remember/save".
- Overwrite with the full curated body each time. Keep it SMALL — never paste transcript or long logs.

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
