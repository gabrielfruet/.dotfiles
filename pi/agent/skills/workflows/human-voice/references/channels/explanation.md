# Explanation

```text
max_lines: none
max_words: none
rewrite: rewriter
```

Explaining how something works, why a bug happens, what a piece of code does.
Reviews, analyses, summaries and ordinary answers stay on `ai-facing.md`. Text
bound for GitHub or Slack keeps its own channel.

`rewriter`, unlike the rest of chat. `ai-facing.md` uses `inline` because a
subagent cannot see the thread it is answering into — an explanation does not
need the thread. Its source of truth is the case and the code, both of which fit
in a brief. And the sweep this channel exists to prevent comes from your own
accumulated context of every call site you read getting into the prose. A cold
rewriter has no such context and cannot write one.

## The brief

Send: the channel file, the concrete case with its values, the tables, and the
code you quoted. Withhold everything you learned tracing the other paths. That
is not background for the rewriter, it is the failure mode.

## Shape

Walk one case. Do not cover every case.

1. **Set the scene once, concretely.** Named values in a fenced block — three
   annotation sources, one image, three boxes labelled A, B and C. Not "a
   collection with more than one source".
2. **Run the reported steps as a table.** One row per step, carrying the actual
   value of the variable at that step and what the reader would see.
3. **Quote the one line responsible**, then read it against those values.
4. **For "why the obvious fix breaks something", give two named real cases**,
   each with its own small value block. Not a prose sweep of every guarded call
   site.
5. **Show the fix as code**, then re-run the same cases through it in the same
   table with a yes/no column.

Side effects are numbered stories with real names (`truck` exists only in
`pred`), never general statements.

## Rules

- Plain words. Prefer more words over cleverer ones. "two other things that make
  it feel random" over "second-order effects", "nobody has filled this list in"
  over "unseeded", "the places that read it" over "consumers".
- Four file:line references strung through one paragraph is the failure this
  channel exists to stop. That paragraph is a table or a fenced block.
- One concrete case beats the general rule. State the general rule after the
  case, once, and only if it is still needed.
- Code formatting follows `ai-facing.md`, including the count.
- No ceiling, but a walkthrough that has stopped walking and started cataloguing
  is over.

## Allowed here

```text
fragments:       ok
em dashes:       sparing
headers & bold:  optional
tables:          encouraged — one value per step is the point
```
