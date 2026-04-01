---
name: subagent
description: Spawn a subagent to run a task. Use when you want to delegate work to a separate pi instance.
---

# Subagent Skill

Spawn a subagent to run a task independently.

The script is at `~/.pi/agent/skills/subagent/subagent.sh`

## Usage

```bash
./subagent.sh "your prompt here"
```

### Options

- `--model <model>` - Model to use (use minimax by default, `minimax/MiniMax-M2.5`)
- `--thinking <level>` - Thinking level: `off`, `low`, `medium`, `high`
- `--cwd <dir>` - Working directory

### Examples

```bash
./subagent.sh "List files in src/"
./subagent.sh "Find all TODO comments" --model minimax/MiniMax-M2.5
```
