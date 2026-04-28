---
name: skill-writter
description: Always load when you need to write some skill.
---

Naming: lowercase hyphens, 1-64 chars, matches folder

Frontmatter:
```
---
name: skill-name
description: What it does/ When to load
---
```

Tips:
- Keep under 50 lines
- Use code examples sparingly
- Prefer simple list of rules
- Do not repeat yourself.
- Description helps agent decide when to use
- Frontmatter must match directory name
- Can reference other skills - agent can load them with `skill(name="other-skill")`
- In `.pi/agent/skills/` — e.g., `~/.pi/agent/skills/skill-name/SKILL.md`

## Trigger (Most Important)

The description is the trigger - it tells the agent WHEN to use this skill.

**Good triggers:**
- "Use when user asks to analyze a task and create a subagent delegation plan"
- "Use when staging or committing"
- "Use when user wants to create, read, edit, or manipulate Word documents"

**Bad triggers:**
- "Does X" - too vague
- "Helps with Y" - passive, unclear when to activate
- "For Z tasks" - ambiguous

**Rule:** Write the trigger as "Use when..." in present tense. Specific enough to avoid false matches, general enough to catch all relevant cases.

**Checklist:**
- Could you write "Use when..." before the description?
- Does it match actual user requests you've seen?
- Will the agent recognize it without ambiguity?
- Is it more specific than "anything related to X"?

## Testing

After writing a skill, verify it loads correctly:
1. Read the file to check frontmatter matches directory name
2. Check syntax (valid YAML frontmatter, no obvious markdown errors)
3. Test in context: ask the agent to use the skill
4. Check that description triggers loading correctly
