---
name: skill-install
description: Fetch and install skills from GitHub, URLs, or skill ecosystems. Use when asked to install, add, fetch, or ingest a skill.
---

# Skill Install

## GitHub: Single Skill

```bash
mkdir -p ~/.pi/agent/skills/NAME
curl -s "https://raw.githubusercontent.com/USER/REPO/main/skills/NAME/SKILL.md" -o ~/.pi/agent/skills/NAME/SKILL.md
```

## GitHub: Full Repo

```bash
curl -s "https://api.github.com/repos/USER/REPO/contents/skills" | jq -r '.[].download_url' | while read url; do
  NAME=$(echo "$url" | sed -n 's|.*/skills/\([^/]*\)/SKILL\.md.*|\1|p')
  [ -n "$NAME" ] && mkdir -p ~/.pi/agent/skills/$NAME && curl -s "$url" -o ~/.pi/agent/skills/$NAME/SKILL.md
done
```

## Raw URL

```bash
curl -s "https://..." -o ~/.pi/agent/skills/NAME/SKILL.md
```

## npm (if package)

```bash
npx skills add USER/REPO
```

## Verify

1. File exists: `ls ~/.pi/agent/skills/NAME/SKILL.md`
2. Frontmatter valid: `head -3` has `name:` and `description:`
3. Name matches dir: frontmatter `name: X` == directory `X`

## Common Sources

| Source | URL |
|--------|-----|
| Superpowers | `obra/superpowers` |
| pi-skills | `badlogic/pi-skills` |
| Raw GitHub | `https://raw.githubusercontent.com/USER/REPO/main/...` |

## Adapting Imported Skills

When installing from elsewhere, **always adapt** to your style:

- Trim verbose sections (diagrams, long checklists, 500-line guides)
- Keep: trigger conditions, core rules, essential commands
- Your style: concise, rules-based, under ~50 lines
- Example: if imported skill has a 50-line flowchart → condense to 3 bullet rules

## Update

```bash
curl -s "https://raw.githubusercontent.com/USER/REPO/main/skills/NAME/SKILL.md" -o ~/.pi/agent/skills/NAME/SKILL.md
```
