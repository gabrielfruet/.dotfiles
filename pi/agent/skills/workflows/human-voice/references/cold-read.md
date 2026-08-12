# Cold read

How to brief the flagger subagent. The briefing does most of the work: the same
agent given the same draft returns useful findings or noise depending almost
entirely on how you frame the task.

The flagger only diagnoses. A **second** subagent does the rewrite, and never
sees the flagger's context — a rewriter that also critiqued anchors on its own
critique.

## What to include

- **The draft.** Nothing around it.
- **The register**, as a bare label: "internal Slack message", "GitHub issue",
  "PR description". Without this the flagger reports correct choices as errors,
  like a lowercase opener in chat or a fragment used for pacing.
- **The word ceiling**, the channel file's `max_words`. A spec, not reasoning, so
  it doesn't violate the withhold rule below. Given a target, the reader can say
  the piece hasn't earned its length; given nothing, it judges prose in the
  abstract and reports clean.
- **Voice samples**, if the user supplied any, labeled as the target voice. This
  turns a generic humanness check into a match check, which is a stronger test.

## What to withhold

- **That it was AI-written.** The important one. Ask a model to find LLM tics in
  an AI draft and it will find them, present or not, and you end up rewriting
  clean sentences into worse ones chasing phantom flags.
- **Your reasoning for any choice.** The justifications are the contamination you
  spawned the subagent to escape. If it knows why the third paragraph is shaped
  that way, it stops being a cold reader.
- **The blocklist.** Let it react first. Feeding it the list turns independent
  reading into pattern-matching, and you lose the tics you hadn't thought to
  write down. Check `blocklist.md` yourself afterward, against what it missed.

## Brief

Send roughly this:

```text
Read the text below. It's a <register>, and it should come in
under <max_words> words.

Tell me whether it reads as written by a person or as generated
text, and point at the specific evidence either way.

Look at:
- sentence and paragraph length variation
- repeated structural patterns
- phrases that appear more often in machine-written text than in
  writing by actual people
- padding: sentences that could be deleted without loss
- whether it commits to positions or hedges

Then count the words and state the count. If it's over the
ceiling, name what you would cut to get under: whole sections
first — a table, an aside, an example — ranked, with the words
saved for each. The ceiling is fixed and something has to go, so
"it's all load-bearing" is not an available answer. A section
being referenced elsewhere doesn't protect it; the reference gets
cut too.

Report each finding as: location, what's wrong, severity
(high/medium/low). Do not rewrite anything and do not suggest
replacements — I only want the diagnosis.

Then give one overall verdict: human, uncertain, or machine.

---
<draft>
```

With voice samples, add before the draft:

```text
Here is writing by the person this should sound like. Judge the
text against this voice, not against good writing generally.

---
<samples>
```

## Reading the result

The overall verdict is the cheapest signal. "Human" with only low-severity
findings means ship it. "Machine" with structural findings means the cut pass
didn't cut enough; go back and cut before rewriting sentences.

A cold read cannot tell you the piece is too long. It sees prose, not a budget.
"No padding found" means the sentences are earning their place; it says nothing
about whether the piece needed that table, because a section can be entirely
load-bearing sentences and still not belong.

The forced-cut question exists because asking *whether* something is droppable
doesn't work. Given a yes/no, a reader defends what it sees: a table the prose
points at ("the timings below") reads as load-bearing precisely because cutting
it would break the reference. Ask instead what goes to reach the ceiling, and the
same reader ranks that table first. Same draft, same reader, opposite answer.

Triage before passing anything to the rewriter:

- Structural flags (uniform paragraphs, everything in threes, closing summary) —
  almost always act on these.
- Phrase flags — act unless the word is load-bearing technical vocabulary.
- Register flags — check the channel file first; the flagger may not know a
  fragment was deliberate.
- "Could be more engaging", "consider adding an example", "the tone is somewhat
  flat" — ignore. Flatness is the goal.

## Optional: blind A/B

With two candidate versions and no clear preference, give a fresh subagent both,
unlabeled and in random order, and ask which reads more like a person wrote it
and why. Cleaner signal than critique: it forces a choice instead of allowing a
list of hedged observations. Don't reveal either version's provenance, and don't
say one is a revision of the other.

## Optional: split the concerns

For long pieces, two flaggers beat one. Give the first the structural question
only (length variation, repeated patterns, padding) and the second the phrase
question only. Phrase-hunting crowds out structural reading when one agent does
both, and structural tells matter more.

Not worth it under roughly 800 words.
