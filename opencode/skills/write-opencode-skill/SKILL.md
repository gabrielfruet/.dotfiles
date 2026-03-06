---
name: write-opencode-skill
description: Create OpenCode skills with proper format
---

Location: `~/.config/opencode/skills/<name>/SKILL.md`

Naming: lowercase hyphens, 1-64 chars, matches folder

Frontmatter:
```
---
name: skill-name
description: What it does
---
```

Tips:
- Keep under 50 lines
- Use code examples sparingly
- Description helps agent decide when to use
- Frontmatter must match directory name
- One concept per skill - split if covering multiple topics
- Can reference other skills - agent can load them with `skill(name="other-skill")`
- In .dotfiles repos, write to `~/.dotfiles/opencode/skills/`
