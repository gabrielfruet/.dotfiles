---
name: codebase-exploration
description: Use when the user asks to explore a repository, trace codepaths, map entry points, compare abstractions, or gather implementation context without changing files.
---

# Codebase Exploration

Use this skill for read-only investigation of an existing codebase.

## Rules
- Never edit, write, scaffold, or refactor code.
- Prefer `rg`, `find`, `read`, and `bash` for inspection.
- Before editing or citing a file, confirm you are inspecting the intended checkout.
- If the needed source lives in a GitHub repo and raw URLs fail, use `gh api repos/<owner>/<repo>/contents/<path>?ref=<sha>` or `gh api search/code` as a fallback.
- Start with current behavior, then narrow to the smallest change surface.
- Trace where logic lives, how data/config flows, and what gates behavior.
- Call out naming conventions, config patterns, hidden constraints, and risks.
- If the request is unclear, ask one clarifying question or state the ambiguity.

## Output order
1. Relevant codepath summary
2. Files/classes/functions that matter
3. How it is configured today
4. Minimal files/codepaths to change
5. Risks / blockers / ambiguities
6. Optional implementation plan

## Style
- Be concrete and file-path driven.
- Prefer evidence over guesses.
- End with a compact implementation-ready context summary, not a design spec.