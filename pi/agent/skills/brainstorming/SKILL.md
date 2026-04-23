---
name: brainstorming
description: Use before any creative work — features, components, functionality. Explores intent, requirements, and design before any code.
---

# Brainstorming

**HARD GATE:** Never write code, scaffold, or implement until user approves a design.

## Process

1. **Explore context** — files, docs, recent commits
2. **Ask questions** — one at a time, prefer multiple choice
3. **Propose 2-3 approaches** — with trade-offs, lead with recommendation
4. **Present design** — scaled to complexity, get approval section by section
5. **Write spec** — save to `docs/YYYY-MM-DD-<topic>-design.md` and commit
6. **Self-review** — fix placeholders, contradictions, ambiguity inline
7. **User reviews spec** — wait for approval
8. **Transition** — invoke `plan-mode` skill for implementation plan

## Key Rules

- One question per message
- "Simple" projects still need a design (even if short)
- If project has independent subsystems → decompose first, brainstorm each separately
- YAGNI ruthlessly — remove unnecessary features
- Incremental validation — present, get approval, then proceed

## Design Doc Template

```markdown
# <Topic> Design

## Context
[Current state, what needs to change]

## Design
[Architecture, components, data flow]

## Success Criteria
[How we know it works]
```

## Self-Review Checklist

1. Any TBD/TODO placeholders? → fix
2. Sections contradict each other? → fix
3. Scope too large for one plan? → flag
4. Ambiguous requirements? → pick one, make explicit