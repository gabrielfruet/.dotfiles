# Feedback

Corrections the user gave on the agent's writing, captured verbatim and left
alone until consolidated.

Two rules, both in `SKILL.md`:

1. Append an entry whenever the user corrects the voice, length or shape of
   something the agent wrote. Record what happened; propose nothing.
2. **Never read this folder while drafting.** Entries have zero effect on output
   until a consolidation pass folds them into the channel files. A rule that
   isn't in a channel file isn't in force.

## Entry format

One file per entry, `YYYY-MM-DD-<short-slug>.md`:

```markdown
---
date: 2026-08-12
channel: pr-description
---

## What was written

<the offending text, verbatim>

## What the user said

<their exact words, verbatim>
```

`channel` is the filename stem from `references/channels/`, or `all` when the
correction isn't channel-specific.

Keep it to those two sections. No proposed rule change, no diff, no analysis of
why the draft was wrong. The point of capture is that it costs nothing and stays
honest; the moment an entry starts arguing for a fix, it stops being evidence and
starts being a theory.

## Consolidation

Runs on request only. The trigger is the user saying something like "consolidate
human-voice feedback".

1. Read every entry in `feedback/`, skipping `applied/`.
2. Group by `channel`. Entries marked `all` target `SKILL.md`.
3. Propose one diff per affected file. Several entries pointing at the same
   underlying habit become one rule, not three.
4. Wait for approval. `APPEND_SYSTEM.md` already requires approval before any
   skill edit, and this is no exception.
5. On approval, apply the diffs, then `mv` each applied entry into `applied/`.

Entries are archived rather than deleted. The archive is how you later tell
whether a rule came from real friction or from someone's theory about writing.

No entry is committed, pending or applied — the `.gitignore` here drops every
`.md` below it, and the archive stays local to the machine that made it. What
ships is this file, that `.gitignore`, and an empty `applied/` held open by
`.gitkeep` so step 5's move works after a clone.
