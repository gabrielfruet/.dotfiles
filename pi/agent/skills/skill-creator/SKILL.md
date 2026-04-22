---
name: skill-creator
description: Analyzes pi session history to find repetitive patterns. Load when user asks to suggest or create skills.
---

## Usage

`suggest skills [--local|--global]` - analyze and suggest
`create skill <name>` - start creation flow

---

## Suggest Mode

Scripts:
- `./find-sessions.sh [--local|--global]`
- `./extract-prompts.sh <files...>` 
- `./extract-commands.sh <files...>`

Sessions are organized by cwd in filename: `---path--` prefix. Use `--local` to filter by current working directory.

Reason over output. Look for repeated commands (3+), similar prompts, same sequences.

Output: simple list with name, confidence, pattern, count.

---

## Create Mode

`skill(name="skill-writter")` - load for template and guidance.

Questions: name, description, trigger, inputs, outputs.

Placement:
- Global: `~/.dotfiles/pi/skills/<name>/SKILL.md`
- Local: `.pi/skills/<name>/SKILL.md`

---

## Tips

- Sessions: `~/.dotfiles/pi/agent/sessions/`
- Local sessions have cwd in filename as `---path--`
- A predictable flow 3+ times = candidate skill