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

Load the `skill-writter` skill and follow it — it owns naming, description,
trigger, placement and the verify step. Run the interview it describes (name,
description, trigger, key instructions), write the `SKILL.md`, and verify the
frontmatter name matches the directory.

Placement: `~/.pi/agent/skills/<name>/SKILL.md`.

## Tips

- Sessions: `~/.dotfiles/pi/agent/sessions/`
- Local sessions have cwd in filename as `---path--`
- A predictable flow 3+ times = candidate skill
- Start with description, build instructions from there