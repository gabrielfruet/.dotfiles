---
name: human-voice
description: >-
  Mandatory before writing any prose: Slack, GitHub (PR titles and bodies,
  issues, review comments and replies), Linear, commit messages, plan files,
  and responses to the user in chat. Strips AI voice — self-narration, restating
  the diff, over-justification, hedging, throat-clearing openers and closers —
  and routes by channel. Also use for "make this sound human", "de-AI this", or
  a draft that reads generic. Not conditional on being asked, and staying in
  chat is not an exemption.
---

# Human voice

Route to a channel, read that file, then draft. Not a pass applied afterwards.

## Core failure mode

Output narrates itself: what it did, why, and what the reader should think about
that — when the reader can already see the diff, the commit, or the thread above.

> I added your suggestion on commit X. This change improves readability and
> maintainability, thanks for pointing it out!

versus `Applied, thanks!` — same information. The diff shows what changed; the
message carries only what the diff can't.

## Route first

Files live in `references/channels/`.

| Channel | File | max_lines | max_words | Rewrite |
|---|---|---|---|---|
| PR description | `pr-description.md` | 20 | 200 | rewriter |
| GitHub issue | `gh-issue.md` | 40 | 300 | rewriter |
| Linear issue | `linear-issue.md` | 25 | 200 | rewriter |
| PR review comment (as reviewer) | `pr-review-comment.md` | 6 | 60 | rewriter |
| PR review reply (as author) | `pr-review-reply.md` | 2 | 25 | inline |
| Slack, WhatsApp, team chat | `slack.md` | 6 | 40 | inline |
| Commit message | `commit-message.md` | 5 | 50 | inline |
| Plan file | `ai-facing.md` | none | none | inline |
| Subagent brief | `ai-facing.md` | none | none | inline |
| Chat response to the user | `ai-facing.md` | none | none | inline |
| Explanation, walkthrough | `explanation.md` | none | none | inline |
| Social post (LinkedIn) | `social-post.md` | none | none | inline |
| Docs, README | `simple-english` skill | — | — | — |

No matching row: pick the nearest and say which. A PR body — gathering and
shaping — lives here in `pr-description.md`; `write-pr-description` routes to it.

Every response to the user is routed. Staying in chat is not an exemption — a
review, an analysis or a summary you hand back in chat reads against
`ai-facing.md` like anything else on the table.

Route on what the answer does, not on how the question was phrased. A draft that
walks one case step by step — values changing, a mechanism unfolding — is an
explanation and takes `explanation.md`, even when the question was "so you think
X?". Re-route the moment the draft starts walking; never finish it on the wrong
channel. A review, an analysis or a summary stays on `ai-facing.md`.

Text bound for another channel keeps that channel. A review comment drafted
inside a chat response takes `pr-review-comment.md`, its 60-word ceiling and its
receipt, whether you post it this turn or hold it for approval. Routing the
wrapper does not route what it contains.

## Universal rules

True everywhere. Fragments, em dashes, headers, bold and first-person opinion are
**not** here — each channel decides those.

- No self-narration, no restating the diff, no throat-clearing openers or closers.
- No paragraph justifying an uncontroversial fix. Commit to a position and cut
  hedges on claims you actually hold.
- Hedge the inference, never the measurement. Give the sample size when it matters.
- Vary sentence length. Uniform mid-length rhythm is the loudest tell.
- Break the pattern of three. No closing summary that restates the body.
- Cut adjectives, intensifiers and editorial connectives that carry no fact:
  `robust`, `straight`, `already`, `a handful of`, `holds up`, `where it runs out`.
- Long paths, conditions and signatures go in fenced blocks, not inline backticks.
- Never invent a fact. Every figure, filename and flag traces back to a source.

## Process

Run every step, every time. Reading the channel file is step zero, not the
process — "the channel file was already read" is not an exemption.

1. **Draft** against the channel file. Aim for unremarkable, not clever.
2. **Cut** to `max_words`. State the before and after count; an unstated count
   means the pass did not run. Run the receipt script on every draft, for every
   channel, and never write a count by hand:

   ```bash
   scripts/receipt.py <channel> < draft.md
   ```

   It prints the receipt line with the word and mixed-sentence counts, then the
   channel's rules. Check the draft against those rules before shipping. Whole
   sections go before sentences do.
   When the user says trim, shorten or "make it concise", cut claims, not words.
   Count the claims before and after and put both in the receipt. A version
   carrying the same claims in fewer words was not trimmed, and one whose
   sentences lost their subjects and verbs is worse than the original, not
   shorter.
3. **Rewrite** per the table's last column:
   - `inline` — check the draft against `references/blocklist.md` (phrases) and
     `references/patterns.md` (constructions, and what *not* to flag), ship.
   - `rewriter` — one subagent. Give it the channel file, the ceiling and the
     source of truth. Withhold your reasoning; escaping it is why you spawned it.
     Skip it when the draft is already cold: a subagent that wrote the body from
     `git diff` and `git log` alone never had your reasoning to escape, so the
     step is done — check it inline and ship.
   - `flagger + rewriter` — not a default. Escalate only for an external or
     public-facing repo, or when the user asks. Its two sequential subagents cost
     minutes — 16 on a 170-word body — and on an internal PR the cold reader
     returns "human" before it starts. A cold reader diagnoses first
     (`references/cold-read.md`), then a **second** subagent rewrites, never
     seeing the flagger's context.

One receipt line per channel in the response, not one per response. A chat
answer carrying a review reply ships two lines. A nested draft with no line of
its own was never routed — stop and read its channel file. No line means the
process did not run.

```text
channel: pr-review-comment | 142 → 54/60 words | mixed 0 | rewriter
channel: ai-facing | 180/none words | mixed 0 | inline
channel: linear-issue | 190 → 88/200 words | mixed 0 | claims 7 → 3 | rewriter

a chat answer carrying two review replies:
channel: ai-facing | 120/none words | mixed 0 | inline
channel: pr-review-reply | 44 → 19/25 words | mixed 0 | inline
```

The mixed count follows the countable rule in `ai-facing.md` under Code
formatting, on every channel. A nonzero count means the draft is not finished. Add the `claims` field whenever the user
asked to trim.

Then check the facts survived: every figure and filename in the source appears in
the rewrite or was cut on purpose. Only you saw the original evidence.

## Feedback

When the user corrects the voice, length or shape of something you wrote, the
`skill-feedback` skill captures it: one entry under that skill's
`entries/human-voice/`, never a directory inside this one, with the channel name
in `scope:`. Record it, change nothing else. Never read those
entries while drafting — they are inert until an approval-gated consolidation
pass folds them into the channel files.

Append new tics to `references/blocklist.md` as you catch them; it is meant to grow.
