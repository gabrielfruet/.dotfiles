---
name: subagent
description: Spawn a subagent to run a task in parallel. Use when you want to delegate work to a separate pi instance.
---

# Subagent Skill

Spawn a subagent to run a task independently. The subagent completes its work and returns the result.

## Setup

No setup required. Just use the script.

## Usage

```bash
./subagent.sh "your prompt here"
```

### Options

- `--model <model>` - Model to use (e.g., `github-copilot/claude-haiku-4.5`, `github-copilot/claude-sonnet-4`)
- `--thinking <level>` - Thinking level: `off`, `low`, `medium`, `high`
- `--cwd <dir>` - Working directory for the subagent

### Examples

```bash
# Simple
./subagent.sh "List files in src/"

# With options
./subagent.sh "Find all TODO comments" --model github-copilot/claude-haiku-4.5 --thinking off

# Different cwd
./subagent.sh "Run tests" --cwd /path/to/project
```

## How It Works

1. Spawns pi in RPC mode (`pi --mode rpc --no-session`)
2. Sends the prompt
3. Waits for completion
4. Extracts the final response from the agent_end message
5. Returns the text output
