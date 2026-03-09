---
name: subagent
description: Spawn a subagent to run a task in parallel. Use when you want to delegate work to a separate pi instance.
---

# Subagent Skill

Spawn a subagent to run a task independently.

## Usage

```bash
./subagent.sh "your prompt here"
```

### Options

- `--model <model>` - Model to use (e.g., `github-copilot/claude-haiku-4.5`)
- `--thinking <level>` - Thinking level: `off`, `low`, `medium`, `high`
- `--cwd <dir>` - Working directory

### Examples

```bash
./subagent.sh "List files in src/"
./subagent.sh "Find all TODO comments" --model minimax/MiniMax-M2.5
```
