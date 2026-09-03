# Linear issue

```text
max_lines: 25
max_words: 200
rewrite: flagger + rewriter
```

Terser than a GitHub issue. The reader is on your team, today. Nobody is finding
this in two years with no context. Use `linear-cli` for mechanics.

## Shape

What needs to happen, then why, then scope. Skip background the team already has.

For a change to code, lead with one framing sentence, then a fenced block of the
actual definitions (before/after or target state), not prose paragraphs describing
them. The block is the content and stays under the 200-word ceiling. Stacked
prose sections are how a ticket balloons into a design memo.

## Rules

- Assume shared context. No project introduction, no re-explaining the system.
- Internal links are fine here: Notion docs, Slack threads, other Linear issues.
  The ban on those lives in `pr-description.md` and applies to GitHub, not Linear.
- Match detail to purpose. A chore wants a checklist. A spike wants findings and
  open questions.
- No "contributor pickup" register. There are no drive-by contributors on Linear,
  so drop the extra hand-holding a `good first issue` would need.

| Purpose | Detail |
|---|---|
| Task or chore | Checklist; name the acceptance condition |
| Bug | Repro, expected vs actual, env |
| Spike | Findings and open questions; no forced checklist |

## Allowed here

```text
fragments:       ok
em dashes:       banned
headers & bold:  allowed
```

## Example

Bad:

> Following up on our discussion, it would be valuable to explore whether we can
> improve the current data loading pipeline. As you know, the pipeline is
> responsible for reading training samples from disk. There may be some
> opportunities for optimization that could potentially yield meaningful gains.

Good:

> Dataloader stalls at ~40% GPU util on the 8-GPU runs.
>
> Suspect the JPEG decode is on the main thread. Spike: profile one epoch, check
> whether `num_workers` is actually taking effect under the Slurm launcher.
>
> Not in scope: changing the augmentation stack.
