---
description: Conduct deep research on a topic using parallel websearch
---

# Deep Research Prompt

Use parallel websearch to research: $@

---

## Your Mission

You are a research assistant. Conduct thorough, multi-batch web research following this workflow.

---

## Phase 1: Discovery (Batch 1)

Run 8 parallel searches across 4 dimensions:

### Dimension 1: Core Overview
- `$TOPIC overview definitions how it works`
- `$TOPIC fundamentals getting started guide`

### Dimension 2: People & Projects  
- `$TOPIC key maintainers authors github`
- `$TOPIC important repositories tools github`

### Dimension 3: Examples & Usage
- `$TOPIC site:reddit.com real usage discussion`
- `$TOPIC site:github.com examples demonstrations`

### Dimension 4: Community & Trends
- `$TOPIC twitter x discussion trends 2026`
- `$TOPIC hacker news site:news.ycombinator.com`

Replace `$TOPIC` with the actual topic from the user's request.

---

## Phase 2: Deepening (Batches 2+)

Based on Batch 1 results, run 2 more batches following up on:

1. **Top hits**: Search for more info on interesting repos, people, or tools discovered
2. **Niche angles**: Search specific communities, alternative names, or related topics
3. **Real-world usage**: Find actual implementation examples, case studies, user experiences

---

## Phase 3: Synthesis

Create a research document in `~/research/` directory.

### Directory Structure
```
~/research/
└── {topic-slug}/
    ├── README.md
    ├── YYYY-MM-DD-{topic-slug}.md
    └── raw-searches/
        ├── batch-1.txt
        ├── batch-2.txt
        └── batch-3.txt
```

### Topic Slug
- Lowercase
- Hyphenated
- Example: "ai-coding-agents" → `ai-coding-agents/`

---

## Document Sections

### README.md (Quick Reference)
```
# {Topic}

Quick summary: 2-3 sentences

## Key People
- [Name](link) - brief description

## Key Projects
- [Repo](link) - brief description with stars

## Key Resources
- [Resource](link) - what it is

## Next Steps
- Suggest 2-3 actions based on findings
```

### Main Document (YYYY-MM-DD-{topic}.md)
```
# {Topic} Research

**Date:** YYYY-MM-DD  
**Depth:** {quick|deep|exhaustive}

## Executive Summary
2-3 paragraphs covering the landscape, key players, and important findings

## Key People
| Person | GitHub/Twitter | Key Contribution |
|--------|----------------|------------------|
| Name | @handle | What they did |

## Key Projects
| Project | GitHub Stars | Description |
|---------|--------------|-------------|
| name | ##k | What it does |

## Key Resources
| Resource | Link | What It Offers |
|----------|------|----------------|
| name | link | brief description |

## Usage Patterns
Real examples from Reddit, Twitter, Hacker News discussions

## Open Questions
Areas that need more research or clarification

## Sources
All search results with links
```

---

## Parallel Execution Pattern

Use this pattern for parallel searches:

```bash
mkdir -p /tmp/research-$$
cd /tmp/research-$$

{
  ddgs text -q "query1" -m 15 > batch1-1.txt &
  ddgs text -q "query2" -m 15 > batch1-2.txt &
  # ... more searches
} &
PIDS+=($!)
wait "${PIDS[@]}"

# Copy results to ~/research/
mkdir -p ~/research/{slug}/raw-searches
cp /tmp/research-$$/*.txt ~/research/{slug}/raw-searches/
```

---

## Depth Control

| User Request | Batches | Searches | Output |
|--------------|---------|----------|--------|
| "quick research" | 1 | 8 | Summary only |
| "research" or "deep research" | 3 | 24 | Full doc |
| "exhaustive research" | 5+ | 40+ | Comprehensive |

Default to 3 batches if not specified.

---

## Important Notes

- Use `ddgs text -q` for search queries (not `ddgs` alone)
- Use `-m 15` or `-m 20` for max results
- Save raw search results for reference
- Clean up `/tmp/research-*` after saving
- If search returns 0 results, try alternative queries
- Look for recent results (2025-2026 preferred)

---

## Start Now

Begin with Phase 1 - Discovery. Run 8 parallel searches. Then continue through Phase 2 and Phase 3.

Report what you find.
