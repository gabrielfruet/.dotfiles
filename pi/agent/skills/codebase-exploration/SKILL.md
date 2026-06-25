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
- Confirm the active checkout first (`pwd` and `git rev-parse --show-toplevel` or equivalent). If multiple worktrees/checkouts exist, explicitly name which one is authoritative.
- When using upstream docs/changelogs for a dependency, verify the installed or checked-out package version matches the cited source before concluding.
- For API-contract claims, inspect the installed source or checked-out implementation when available, not just signatures or assumptions. Cite exact evidence in the final answer.
- Distinguish observed implementation facts from design suggestions; do not present suggestions as discovered behavior.
- If the needed source lives in a GitHub repo and raw URLs fail, use `gh api repos/<owner>/<repo>/contents/<path>?ref=<sha>` or `gh api search/code` as a fallback.
- Start with current behavior, then narrow to the smallest change surface.
- If the baseline or "original" behavior is unclear, use git history to identify the commit that introduced or removed it and cite the commit hash.
- Trace where logic lives, how data/config flows, and what gates behavior.
- Call out naming conventions, config patterns, hidden constraints, and risks.
- If the request is unclear, ask one clarifying question or state the ambiguity.

## Subagents
- For non-trivial exploration, explicitly consider dispatching a focused read-only subagent via the `subagent` skill.
- One subagent is often enough: use it for a bounded exploration pass such as tracing entry points, mapping config/data flow, comparing similar implementations, or checking history/docs/tests.
- Use multiple subagents only when the branches are genuinely independent.
- Prefer smaller models for these bounded research tasks: `minimax/MiniMax-M3 --thinking high` or `openai-codex/gpt-5.4-mini --thinking high`.
- Give each subagent a narrow prompt, the correct cwd, and an output schema requiring file-path/line evidence.
- Keep subagents read-only. The main agent must synthesize and verify conclusions before answering.

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