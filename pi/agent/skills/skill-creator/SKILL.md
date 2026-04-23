---
name: skill-creator
description: Analyzes pi session history to find repetitive patterns. Load when user asks to suggest or create skills.
---

## Usage

`suggest skills [--local|--global]` - analyze session history and suggest
`create skill <name>` - start creation flow

---

## Suggest Mode

Scripts:
- `./find-sessions.sh [--local|--global]`
- `./extract-prompts.sh <files...>`
- `./extract-commands.sh <files...>`

Run these first, reason over the output to find patterns.

Sessions are organized by cwd in filename: `---path--` prefix. Use `--local` to filter by current working directory.

Look for:
- Repeated commands (3+ times)
- Similar prompts across sessions
- Same command sequences

Output: list with name, confidence, pattern, count.

## Create Mode

1. Run `skill(name="skill-writter")` to load the template
2. Ask the user: name, description, trigger conditions, key instructions
3. Write the SKILL.md with frontmatter
4. Verify frontmatter name matches directory name
5. Test by asking agent to use the skill

### Questions to Ask

- **Name**: lowercase-hyphens format
- **Description**: 1 sentence, when to load this skill
- **Trigger**: What user words/phrases should load it?
- **Key instructions**: What rules/patterns should it follow?

### Placement

- Global: `~/.pi/agent/skills/<name>/SKILL.md`
- Local: `.pi/skills/<name>/SKILL.md`

## Tips

- Sessions: `~/.dotfiles/pi/agent/sessions/`
- Local sessions have cwd in filename as `---path--`
- A predictable flow 3+ times = candidate skill
- Start with description, build instructions from there