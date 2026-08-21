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
- Match the scaffolding to the question. A conceptual "why does this differ"
  answer leads with the mechanism in the reader's terms — what the code is
  *deciding* and why. Headers, tables, file:line and runtime-internal names
  (`PyType_Ready`, `tp_setattro`) are opt-in for a value-by-value trace that
  needs them, not the default. Reaching for them first is what makes the
  plain-language version arrive two tries late.
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

## Example

Same bug: why `SimpleNamespace` graph-breaks under torch Dynamo on 3.10–3.12 but
not 3.13.

Bad (flagged as unclear):

> `PyObject_GenericSetAttr` is the function `object` itself uses. Naming it
> explicitly changes what `PyType_Ready` does: before 3.13, a slot the struct
> names gets a wrapper descriptor published on the type. 3.13 stopped publishing
> those.

Good (landed):

> When your code does `ns.total = x`, Dynamo asks one question: does setting an
> attribute here do anything unusual? It looks up `__setattr__` and compares it
> to the plain one every object gets by default. On 3.13 there is no entry, so it
> finds the plain one, nothing unusual. On 3.10–3.12 there is one, but it is a
> duplicate that does exactly what the plain one does: a copy, not a replacement.
> Dynamo saw a different object, concluded "custom", went looking for Python to
> trace, and found none, because this is written in C. No branch left, so it
> reported a graph break.
