---
name: task-dispatch
description: Execute implementation plans by dispatching subagents per task with pre-flight question phases. Load when tasks are independent and you want to delegate.
---

# Task Dispatch

Dispatch fresh subagent per task with two-phase execution: question collection, then implementation.

## The Problem

Subagents running with `pi --no-session` cannot ask questions mid-execution. They run to completion. So we structure the dispatch in two steps:

```
Phase 1: Collect questions
  Controller → Dispatch implementer (questions-only mode)
  Subagent → Outputs questions and STOPs

Phase 2: Execute with answers
  Controller → Parse questions, relay to user, get answers
  Controller → Re-dispatch implementer with answers
  Subagent → Works autonomously to completion
```

After implementation: same two-stage review as before.

## Process

1. Read plan, extract all tasks with full text and context
2. For each task:
   a. **Phase 1:** Dispatch implementer (questions-only)
   b. Parse subagent output for questions
   c. Present questions to user, get answers
   d. **Phase 2:** Re-dispatch implementer with answers + proceed instruction
   e. Dispatch spec reviewer
   f. Issues found → implementer fixes → re-review
   g. Dispatch code quality reviewer
   h. Issues found → implementer fixes → re-review
3. Mark task complete, move to next

**Never skip review loops or proceed with open issues.**

## Phase 1: Question Collection Prompt

Dispatch implementer with this prompt:

```
You are planning implementation for: [task name]

## Task
[FULL TEXT from plan - paste here, do not read file]

## Context
[Where this fits, dependencies, architectural notes]

## Your Job
Before writing any code, identify everything you need to know to implement this task correctly.

Output your questions in this format, then STOP:

```
 QUESTIONS:
 1. [question about requirements or acceptance criteria]
 2. [question about approach or implementation strategy]
 3. [question about dependencies or assumptions]
 ...

If you have no questions, output:
```
 QUESTIONS:
 None
```
and then STOP.

Do NOT start implementation. Only identify questions.
```

## Phase 2: Execution Prompt

After user provides answers, re-dispatch:

```
You are implementing: [task name]

## Task
[FULL TEXT from plan]

## Context
[Same as before]

## Answers to Questions
[The user answered:]
Q1: [answer]
Q2: [answer]
...

## Your Job
1. Implement exactly what task specifies
2. Write tests
3. Verify it works
4. Commit
5. Self-review (completeness, quality, YAGNI)
6. Report: DONE | DONE_WITH_CONCERNS | BLOCKED

If you encounter something unexpected that wasn't covered by the answers, report BLOCKED with specifics.

Ask nothing. Proceed with implementation.
```

## Spec Reviewer Prompt

```
Review whether implementation matches spec.

## Task Requirements
[FULL TEXT]

## Implementer's Claims
[From implementer's report]

**Read actual code.** Do NOT trust the report.

Check:
- All requirements implemented?
- Any extra/unneeded features?
- Misunderstandings?

Report: ✅ Spec compliant | ❌ Issues: [with file:line refs]
```

## Code Quality Reviewer Prompt

```
Review code quality: clean, tested, maintainable.

**Only run after spec compliance passes.**

Check:
- Each file has clear responsibility?
- Units decomposed for testing?
- Following plan's file structure?
- New files already large? (flag if so)

Report: Strengths, Issues (Critical/Important/Minor), Assessment
```

## Status Handling

| Status | Action |
|--------|--------|
| DONE | Proceed to spec review |
| DONE_WITH_CONCERNS | Read concerns first, proceed to review |
| BLOCKED | Assess blocker: more context / stronger model / break task / escalate to human |

## Model Selection

| Task | Model |
|------|-------|
| Mechanical, 1-2 files, clear spec | cheap |
| Integration, multi-file | standard |
| Architecture, design, broad understanding | most capable |

## Red Flags

**Never:**
- Start on main/master branch without explicit consent
- Skip spec OR quality review
- Proceed with unfixed issues
- Parallel dispatch implementers (conflicts)
- Make subagent read plan (give full text instead)
- Start quality review before spec compliance ✅
- Move to next task with open review issues
- Skip Phase 1 and assume no questions needed (unless task is trivial)

## Integration

| Skill | Use |
|-------|-----|
| `subagent` | Spawn implementer and reviewer subagents |
| `git-workflow` | Commit after each approved task |
| `plan-mode` | Create plan before starting |
| `parallel` | Parallel commands (not subagent dispatch) |
