# Slack

```text
max_lines: 6
max_words: 40
rewrite: inline
voice: required
```

Shortest channel there is. Write 40 words unless the reader asked for a technical
update or an investigation recap; only those get `max_lines: 15`, `max_words: 120`.
"Concise", "quick" and "a short message" mean 40, not 120. A list of caveats is
not a technical update: keep the one or two that change what the reader does.

## Shape

One idea per message. For the longer variant: main result in the first sentence,
then the facts, then what is still uncertain and what is next.

## Audience

Name the reader before drafting: your team, another team, or a customer.

- Your team: what shipped and what they need to know. Not the announcement users
  would get.
- A customer: write as the people who built the product. Never "we found" or
  "turns out" about your own product.
- Anyone whose work comes up: describe it neutrally. Never call their approach
  slow, wrong or "the obvious way".

## Before drafting

Read 2–3 of the user's own messages in that channel or thread. Fetch them if
they are not in context. A message from another channel doesn't count. Save
them to a file and pass it to the receipt with `--voice`; it prints their opener
and closer next to yours. Rewrite until each pair could have come from the same
person. No messages to sample: draft 2–3 tone variants and let the user pick.

## Rules

- No salutations, no sign-offs. Contractions are normal. Fragments only in
  one-liners, never to reach the word count. Periods on one-liners are optional.
- Every number says what it measures and which method got it, in the same
  sentence.
- Almost never needs a bulleted list. Reaching for one means the message is too
  long for Slack.
- No build-up before the result, and no closing "so what this means is" line. The
  last line is a fact or a next step, never a moral.
- Prefer short simple sentences over compound ones stitched together with
  em-dash asides. This matters more here than anywhere; the reader is skimming.
- Name the effect, not the mechanism. Cut file names, function names and API
  terms unless the reader needs them to act. "Reads the installed version so the
  footer isn't hardcoded" beats naming the hook file and the config key.
  Exception: pitching an API to the engineers who own it. Show the call in a code
  block; the block doesn't count toward the 40 words.
- Asking permission for routine work: ask, and stop. Say what you want to do,
  not how you found it — "Fine if I update the nginx config on the proxy host?"
  The diagnosis, the PR link and the caveat wait until someone asks. Hand the
  draft over on its own, with no commentary paragraphs trailing it.
- Read who holds the answer. In a top-level post where nobody does, open a discussion:
  the open question, what it depends on, what you lean toward, then ask what
  people think. Never open with "Proposal". State the lean as "I think", not as
  fact, and keep those hedges through the word cut. End on the question, never
  on a commitment. "Works for you?" is only for someone who can decide. Caveats
  in a thread under the user's own post stay statements, not questions.
- Replying in a thread: answer every question it asked, and end with the next
  step you offer to take ("happy to create issues for this"). Never close by
  offering another version of the message.
- State a deadline as your plan, never as a condition on the reader. "I'll shut
  these down Wed, Oct 7, so flag anything before then" — not "if I don't hear
  back by Wed, I'll shut these down."

## Allowed here

```text
fragments:       one-liners only
em dashes:       avoid
headers & bold:  banned
```

## Example

Bad, fact and inference tangled, dramatic arc, sales-pitch close:

> Ran three comparisons and found the actual lever: it's the learning rate, not
> the schedule we suspected. Run 1 peaked early then declined. Run 2 did the
> same. Run 3, with a lower rate, held steady with no decline at all, which
> inverts our original hypothesis. This isn't just a small win, it fixes the
> core problem.

Good, result first, facts plain, uncertainty stated, no moral:

> Lower learning rate seems to fix the decline we've been seeing.
>
> Runs 1 and 2 (higher rate) both peaked early then dropped off. Run 3 (lower
> rate) held steady, best result so far. Only one run at the lower rate though,
> so still checking whether that holds.
>
> Next: rerun at the lower rate to confirm, then try extending it.
