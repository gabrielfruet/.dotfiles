---
name: agent-planning
description: Interactive planning - load when user asks to plan
---

## Core Rule

**DO NOT MODIFY ANYTHING.** Create a plan only. Wait for user approval before implementing.

## Workflow

1. **Understand the request** - Ask clarifying questions if needed
2. **Create a plan** - Outline steps, files, changes needed
3. **Present to user** - Format as markdown, wait for response
4. **Iterate** - Modify plan based on user feedback
5. **Wait for approval** - Proceed only after user explicitly approves
6. **Implement** - Execute the approved plan

## Plan Format

```markdown
## Plan

### Step 1: [Description]
- File: `path/to/file`
- What: brief change

### Step 2: [Description]
- ...
```

## User Signals

- "Sounds good", "Looks right", "Yes", "Go ahead" → approval (proceed)
- Any modification request → iterate (don't proceed)
- "Actually", "Wait", "What about" → iterate (don't proceed)

## Guidelines

- Keep plans modular and reversible
- Highlight any risks or breaking changes
- Ask if user wants details on any step
- Don't assume - confirm assumptions with user
