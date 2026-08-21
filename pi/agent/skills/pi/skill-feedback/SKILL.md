---
name: skill-feedback
description: >-
  Capture-only log of user corrections to how a skill behaved — its output, its
  process, its rules. Use when the user pushes back on what a skill produced or
  on a step it skipped, and the correction should outlive the session. Also use
  for "consolidate <skill> feedback", the approval-gated pass that folds entries
  back into the skill files. Not for PR review comments; pr-workflow owns those.
---

1. **Append an entry** whenever the user corrects how a skill behaved. Record
   what happened, propose nothing, edit no skill file.
2. **Never read `entries/` while working.** A rule that is not in a skill file is
   not in force. Entries do nothing until consolidation folds them in.

## Entry format

One file per entry, at `entries/<skill-name>/YYYY-MM-DD-<slug>.md`:

```markdown
---
date: 2026-08-13
scope: pr-description
---

## What the agent did

<what it did or wrote, verbatim>

## What the user said

<their exact words, verbatim>
```

`<skill-name>` is the skill's directory name. `scope` narrows the target inside
it — a channel file, a workflow step — dropped when the correction hits the whole
skill. Those two sections and nothing else: no proposed rule change, no diff, no
analysis. An entry that argues for a fix has stopped being evidence.

## Consolidation

On request only, e.g. "consolidate human-voice feedback".

1. Read `entries/<skill>/`.
2. Propose one diff per affected file. Entries on one habit become one rule.
   Before adding a rule, check whether it supersedes or duplicates an existing
   one — replace the old text rather than adding beside it. If the target
   SKILL.md is over its line budget (see `skill-writter`), the diff must remove
   at least as many words as it adds.
3. Wait for approval; `APPEND_SYSTEM.md` requires it before any skill edit.
4. Apply, `mv` each entry to `applied/<skill>/`, remove the emptied directory.

Archived, not deleted: the archive tells you later whether a rule came from real
friction or from a theory. The `.gitignore` in each keeps all of it out of git.
