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
- In .dotfiles repos, write to `~/.dotfiles/pi/skills/`
