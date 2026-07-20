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
5. For every claim about an external/library API or inherited behavior, inspect the source or official docs and cite the exact file/line or docs section. If not verified, label it as unverified and do not build the plan on it.
6. Record user constraints explicitly, including testing preferences such as "no mocks", before proposing the plan.

### Read-only subagent inspection
- For non-trivial plans, explicitly consider dispatching a focused read-only subagent via the `subagent` skill before finalizing the plan.
- One subagent is often enough: use it for a bounded inspection pass such as tests, docs/API usage, config/build/deployment touchpoints, or change-surface discovery.
- Use multiple subagents only when the inspection branches are genuinely independent.
- Prefer smaller models for these bounded research tasks: `minimax/MiniMax-M3 --thinking high` or `openai-codex/gpt-5.4-mini --thinking high`.
- Subagents must not edit, write, scaffold, or implement. Require file-path/line evidence.
- The main agent owns the final plan, verifies/synthesizes subagent findings, and still waits for explicit approval.

### Phase 2: Think Before Coding
- **State assumptions** — If uncertain, say so
- **Present multiple interpretations** — Don't pick silently
- **Push back** — If a simpler approach exists, suggest it
- **Avoid inventing default behavior** — Do not add fallback/default implementations unless the issue requires them or evidence shows they are necessary.
- **Prefer the minimal semantic change** — If an existing method already computes the desired value but discards it, plan to return/propagate that value before proposing new computation paths.
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
- **Test style**: prefer behavior/integration tests over mocks. If proposing mocks, justify why real behavior cannot be tested cheaply.

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
