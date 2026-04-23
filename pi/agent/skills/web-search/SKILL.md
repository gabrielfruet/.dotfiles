---
name: web-search
description: Search the web using DuckDuckGo. Use when you need to find information, facts, documentation, or current events on the internet.
---

# Web Search

Search the web using DuckDuckGo via the `ddgs` CLI tool.

## Usage

```bash
./web-search.sh <query> [max_results]
```

### Arguments

- `query` - Search keywords (required)
- `max_results` - Maximum number of results (optional, default: 5)

### Output

Returns JSON array with search results containing:
- `title` - Result title
- `href` - URL link
- `body` - Result snippet

## Examples

```bash
./web-search.sh "python fastapi tutorial"
./web-search.sh "typescript generics" 10
```

## Important: Temp File Handling

⚠️ **The script writes to `/tmp/agent-research/`**, not the current directory.

When running searches in parallel via the `parallel` skill, output files are saved there. Use absolute paths when referencing results:

```bash
# WRONG - writes to cwd
./web-search.sh "query" > results.txt

# RIGHT - output to a specific temp dir, reference by absolute path
./web-search.sh "query" > /tmp/agent-research/results.txt
cat /tmp/agent-research/results.txt
```

## Parallel Usage Pattern

```bash
mkdir -p /tmp/agent-research
{
    ./web-search.sh "AI agents" > /tmp/agent-research/results1.txt &
    ./web-search.sh "skills" > /tmp/agent-research/results2.txt &
} &
PIDS+=($!)
wait $PIDS
cat /tmp/agent-research/results1.txt /tmp/agent-research/results2.txt
```
