---
name: web-search
description: Search the web using DuckDuckGo. Use when you need to find information, facts, documentation, or current events on the internet.
---

# Web Search

Search the web using DuckDuckGo via the `ddgs` CLI tool.

## Basic Usage

```bash
ddgs text -q "search query" -m 10
```

### Key Options

| Flag | Description | Example |
|------|-------------|---------|
| `-q` | Search query | `-q "AI agents"` |
| `-m` | Max results | `-m 15` |
| `-t` | Time limit | `-t w` (week), `-t m` (month) |
| `-o` | Output file | `-o results.json` |

### Output

Returns numbered results:
```
1.
title       Result Title
href        https://example.com
body        Snippet text...
```

To save as JSON:
```bash
ddgs text -q "query" -m 10 -o /tmp/results.json
```

## Extract Page Content

Extract full content from a URL:
```bash
ddgs extract -u https://example.com -f text
```

Formats: `text_markdown`, `text_plain`, `text_rich`

## Examples

```bash
# Basic search, 10 results
ddgs text -q "python tutorial" -m 10

# Recent results only (this week)
ddgs text -q "AI news" -m 15 -t w

# Save to JSON for programmatic use
ddgs text -q "machine learning" -m 20 -o results.json

# Extract content from a page
ddgs extract -u https://github.com/example/repo -f text
```

## Important: Temp File Handling

⚠️ Always output to a **dedicated temp directory**, not the current working directory.

```bash
# WRONG - writes to cwd
ddgs text -q "query" > results.txt

# RIGHT - output to temp dir
ddgs text -q "query" -m 15 > /tmp/agent-research/results.txt
cat /tmp/agent-research/results.txt
```

## Parallel Usage Pattern

Run multiple searches concurrently using subshells:

```bash
mkdir -p /tmp/agent-research

(ddgs text -q "query1" -m 15 > /tmp/agent-research/01.txt) &
PID1=$!
(ddgs text -q "query2" -m 15 > /tmp/agent-research/02.txt) &
PID2=$!
(ddgs text -q "query3" -m 15 > /tmp/agent-research/03.txt) &
PID3=$!

wait $PID1 $PID2 $PID3
cat /tmp/agent-research/0*.txt
```

## Quick Reference

```bash
# 5 results (default)
ddgs text -q "search terms"

# 20 results
ddgs text -q "search terms" -m 20

# From specific site only
ddgs text -q "search terms site:github.com" -m 10
```
