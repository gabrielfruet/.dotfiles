---
name: human-voice
description: >-
  Write in Gabriel's own voice when the text goes to another person: Slack and
  team chat, GitHub (PR review comments, review replies, issues), Linear issues,
  commit messages, LinkedIn posts, and explanations of how code works. Also use
  for "make this sound like me", "make it more human", or a draft that reads
  stiff or generic. PR descriptions follow pr-workflow.
---

# Human voice

Read `references/voice-samples.md` before drafting. The target is a message
Gabriel could have sent, so match those samples over any rule below.

## Voice

Casual and direct, like talking to a colleague. Gabriel leans with "I think"
and "maybe", ends an open question with "wdyt?", marks small points "Nit:" or
"Not blocking", uses `->` for "becomes", and writes plain names without
backticks. Contractions are normal. No greetings, no sign-offs, no AI footer.

## Readability

- Plain words. More words beat cleverer ones: "nobody filled this in", not
  "unseeded".
- Connected sentences. Join related facts with "and", "so", "because". Never a
  run of fragments, and never one-line drumbeats.
- Outcome before mechanism. Say what the reader sees or gets. Name files,
  functions and API terms only when the reader needs them to act.
- No names the reader hasn't seen: run names, session artifacts, internal
  shorthand. Describe the thing or link it.
- When trimming, cut information, not words. Keep every fact the reader needs
  to act and drop the rest whole.
- Never invent a fact. Every number says what it measures.
- Never publish status about a named colleague. Ask them the open question.

Length and density follow `i-have-adhd`. The ceilings below are per channel.

## Channels

| Channel | Ceiling | Shape |
|---|---|---|
| Slack / team chat | 40 words; 120 for a requested technical recap | One idea. Result first. |
| PR review comment | 40 words | Claim, then what happens in one concrete case, then a fix snippet only if not obvious |
| Approval | 15-25 words | Thank one thing, then LGTM |
| PR review reply | 25 words | One sentence |
| Linear issue | 200 words | What, why, scope. Code change: one framing sentence + fenced block |
| GitHub issue | 300 words | Proposed API first, then context, then scope |
| Commit message | 50 words | Imperative subject; body only for a non-obvious why |
| LinkedIn post | none | Connected sentences, one person thinking out loud |
| Explanation | 100 words | See `references/explanation.md` |

**Slack.**
- A discussion opener states the lean with "I think" and ends on the question
  ("wdyt?"), never on a commitment.
- Asking permission for routine work: ask and stop. "Fine if I update the nginx
  config on the proxy host?"
- A thread reply answers every question asked and ends on the next step you
  offer to take.
- A deadline is your plan, not a condition on the reader: "I'll shut these down
  Wed, so flag anything before then."
- Post in pieces when there is a lot to say, not one wall.

**Review comment.**
- One claim per comment, anchored inline, at most one softener.
- Don't cite function names as evidence; say what happens.
- Rewriting Gabriel's draft: keep his phrasing and change only the facts.
- Draft in chat and wait for approval before posting.

**Review reply.**

```text
applying a suggestion   Applied, thanks!  /  Good catch, fixed in [this commit](url).
disagreeing             Kept it as-is: X breaks under Y.
asking for an action    @alice could you merge? Windows failure is unrelated.
```

A human reviewer outranks a bot. Link the commit, never a bare hash.

**GitHub (issues, commits).** Nothing internal: no Linear IDs, customer names,
Notion or Slack links. The ticket ID lives in the branch name. In a public repo,
an issue is written for a contributor with no context.

**Linear.** Internal links are fine. Written so a teammate with product context,
but not your session context, can act on it.

**Code in prose.** Short identifiers can go inline. Long paths, conditions and
signatures go in their own fenced block, between prose paragraphs.

**Em dashes.** Avoid them everywhere except explanations.
