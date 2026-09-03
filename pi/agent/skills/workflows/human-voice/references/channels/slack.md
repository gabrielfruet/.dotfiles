# Slack

```text
max_lines: 6
max_words: 40
rewrite: inline
```

Shortest channel there is. Write 40 words unless the reader asked for a technical
update or an investigation recap; only those get `max_lines: 15`, `max_words: 120`.
"Concise", "quick" and "a short message" mean 40, not 120.

## Shape

One idea per message. For the longer variant: main result in the first sentence,
then the facts, then what is still uncertain and what is next.

## Rules

- No salutations, no sign-offs. Contractions are normal, so are fragments.
  Periods on one-liners are optional.
- Match the thread's existing register rather than imposing formality on it. If
  the channel is casual, be casual; if it is a status channel, be terser still.
- Almost never needs a bulleted list. Reaching for one means the message is too
  long for Slack.
- No build-up before the result, and no closing "so what this means is" line. The
  last line is a fact or a next step, never a moral.
- Prefer short simple sentences over compound ones stitched together with
  em-dash asides. This matters more here than anywhere; the reader is skimming.
- Name the effect, not the mechanism. Cut file names, function names and API
  terms unless the reader needs them to act. "Reads the installed version so the
  footer isn't hardcoded" beats naming the hook file and the config key.

## Allowed here

```text
fragments:       encouraged
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
