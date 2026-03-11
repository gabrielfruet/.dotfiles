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
