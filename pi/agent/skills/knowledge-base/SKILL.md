---
name: knowledge-base
description: Access the knowledge base to retrieve relevant information before executing tasks. Agent should load this automatically.
---

## Usage

Before starting any task, run the index script to see available knowledge:

```bash
~/.dotfiles/pi/agent/skills/knowledge-base/index.sh
```

This prints all knowledge entries with their descriptions, domains, and tags.

## Retrieval

1. Run the index script
2. Match entries against the user's request using domain/tags
3. Read relevant entry files with `read` tool
4. Include the knowledge in your context before executing

## When to Use

- User mentions a domain you have knowledge about (e.g., PyTorch, Python)
- Task involves fine-tuning, training, or model work → check PyTorch knowledge
- Task involves coding → check Python knowledge
- You're unsure about best practices → check relevant knowledge
