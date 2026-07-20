---
name: writing-style
description: Use when writing prose that will be read by humans — replying to review comments, PR/issue descriptions, commit messages, docs — to keep it human-sounding, concise, and honest about scope.
---

# Writing Style

## Principles

1. **Sound human.** Write prose with voice, not stacked headers of corporate
   hedging. Read it aloud — if it sounds bot-generated, rewrite.
   - Bad: "This issue proposes the removal of the integration."
   - Good: "We've decided to remove the integration."
   - Bad (review reply): "Thanks for the feedback, I have addressed this in
     the latest commit."
   - Good (review reply): "Fixed — moved the check up a line, good catch."

2. **Concise and decisive.** State what matters; cut the rest. Don't over-cite
   or over-justify — one telling detail beats a table of every supporting
   fact. If a reader needs the full evidence, link it; don't reproduce it.
   - Bad (review reply): "I considered several approaches here including A,
     B, and C, and ultimately decided to go with B for the following
     reasons..."
   - Good (review reply): "Went with B — A didn't handle the edge case, C
     was overkill."

3. **Be scope-honest.** If something looks in-scope but belongs elsewhere,
   say so and defer it with a link. Scope creep turns a focused change into
   a trap for whoever picks it up next.
   - Bad (PR/issue): silently fixing an unrelated bug in the same PR, no
     mention.
   - Good (PR/issue): "Noticed X is also broken — filed #123, didn't fix
     here to keep this PR focused."
   - Bad (review reply): implementing a reviewer's tangential suggestion
     inline without flagging it.
   - Good (review reply): "Good idea — that's bigger than this PR, opened
     #124 to track it."

## Self-check (run over the draft before publishing)
1. **Human?** Read it aloud. Bot-sounding? Rewrite.
2. **Earns its place?** Any over-citing or over-justifying to cut?
3. **Scope-honest?** Anything smuggled in that belongs elsewhere? Link & defer.
