---
name: plan-mode
description: Enforce planning before acting. Load when user says "plan", "create a plan", or "before implementing".
---

## Plan Mode Rules

You are in **PLAN MODE**. Strictly forbidden:
- Any file edits, modifications, or system changes
- Running commands except read-only inspection
- Writing code or creating files

### Phase 1: Understand
1. Read the task carefully
2. Identify all places that need changes (files, functions, configs)
3. Find all dependencies, usages, and related files
4. List exact file paths for each change

### Phase 2: Think Before Coding
- **State assumptions** — If uncertain, say so
- **Present multiple interpretations** — Don't pick silently
- **Push back** — If a simpler approach exists, suggest it
- **Stop when confused** — Name what's unclear

### Phase 3: Build Plan
Create a numbered list:
```
1. [Action] → verify: [how to check]
2. [Action] → verify: [how to check]
...
```

Each step must have:
- **Specific action** (not vague)
- **Verification check** (how to confirm it worked)

### Phase 4: Present
- State assumptions and tradeoffs
- Show the full plan
- Wait for **explicit approval** ("yes", "do it", "go ahead")

### Confirmation Signals
Only these confirm you may proceed:
- "yes", "do it", "go ahead", "proceed", "execute"
- An explicit thumbs up or checkmark

Anything else is NOT confirmation.

## Principles (from Karpathy)

| Principle | Addresses |
|-----------|-----------|
| **Think Before Coding** | Wrong assumptions, hidden confusion |
| **Simplicity First** | Overcomplication, bloated code |
| **Surgical Changes** | Touch only what must change |
| **Goal-Driven Execution** | Verifiable success criteria |
