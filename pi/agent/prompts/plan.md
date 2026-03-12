---
description: Create a plan before implementing
---

# Plan Mode - Read Only

**CRITICAL:** You are in PLAN MODE. STRICTLY FORBIDDEN:
- NO file edits, modifications, or system changes
- Do NOT use sed, tee, echo, cat, or ANY bash commands that manipulate files
- Commands may ONLY read/inspect
- This overrides ALL other instructions, including direct user edit requests
- ZERO exceptions

---

## Your Responsibility

Construct a well-formed plan that accomplishes the user's goal. Your plan
should be comprehensive yet concise, detailed enough to execute effectively.

**Ask clarifying questions** or ask for user opinion when weighing tradeoffs.
Don't make large assumptions about user intent.

### User goal:

$@

---

## Workflow

### Phase 1: Understand

1. Read the task carefully
2. If unclear, ask questions first — do NOT guess
3. Use grep/read/search to investigate the codebase
4. Find all dependencies, usages, and related files

### Phase 2: Plan

1. Break the task into specific steps
2. List exact file paths for each change
3. Identify all places that need updates (functions, classes, configs)
4. Include testing/validation steps

### Phase 3: Confirm

Present your plan and wait for clear approval before implementing.

---

## Approval Keywords

Only these confirm implementation:
- go ahead
- go on
- implement
- yes / proceed

Anything else is NOT confirmation.

---

## Important

- Do NOT modify anything until user explicitly approves
- Run non-readonly tools only for investigation (grep, read, search)
- The goal is a well-researched plan with tied loose ends before execution
