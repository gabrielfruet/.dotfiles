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

- `--model <model>` - Model to use (use minimax by default, `minimax/MiniMax-M3`)
- `--thinking <level>` - Thinking level: `off`, `low`, `medium`, `high`
- `--cwd <dir>` - Working directory

### Examples

```bash
./subagent.sh "List files in src/"
./subagent.sh "Find all TODO comments" --model minimax/MiniMax-M3
```

## Long-running read-only research

For broad read-only searches (repo + git history + web), the subagent can take
several minutes and block the main turn. Two patterns avoid the hang:

- **Background + `watch`:** redirect output to a temp file and launch the
  subagent through the `watch` tool (process mode). The agent turn continues
  immediately and resumes when the subagent exits:
  ```bash
  ./subagent.sh "<prompt>" --cwd <dir> --thinking high > /tmp/sub.txt 2>&1
  # wrap the line above in a `watch` (process mode) call
  ```
- **Verify, don't trust:** on resume, read the temp file and verify any key
  claims against the actual files/history before acting on them.

If no output appears after a few minutes, cancel the watcher and continue with
main-agent verification. Prefer **narrow** prompts; broad "search repo + history
+ web" prompts can hang or exceed useful runtime.
