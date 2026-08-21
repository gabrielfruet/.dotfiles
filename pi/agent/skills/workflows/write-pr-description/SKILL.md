---
name: write-pr-description
description: Use to draft a PR description and title from the branch's diff and commits — analyze the changes, group them by area, and produce a goal-first structured Markdown body a reviewer can grasp in under a minute. Invoked by pr-workflow, or directly when asked to "write/generate/describe a PR".
---

# Write PR Description

Draft a PR title and body from the branch's diff and commits. The full
procedure — gather (merge-base / diff / log), shape, length, rules and examples —
lives in one place: `human-voice`'s `references/channels/pr-description.md`. Load
that channel and follow it.

Write the body to a file and hand off: `pr-workflow` owns `gh pr create/edit` and
the CI loop; this skill only produces the text.
