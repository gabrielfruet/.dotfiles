# PR review reply (as author)

```text
max_lines: 2
max_words: 25
rewrite: inline
```

Replying to a reviewer on your own PR. For raising an issue on someone else's
code, use `pr-review-comment.md`.

## Shape

One sentence, unless there is a genuine open question. Pick the matching default:

```text
applying a suggestion   Applied, thanks!  /  Good catch, fixed.
disagreeing             Kept it as-is: X breaks under Y.
pushing back or asking  Why not just Z here?
```

## Rules

- No restating the diff. GitHub already renders it.
- No explaining the fix. If the reasoning is genuinely non-obvious, one clause.
- No thanking-with-justification.
- Disagreement gets one clause of reasoning, not a paragraph.
- A human reviewer outranks a bot. When a human says a change is unnecessary,
  drop it rather than defending it.

## Allowed here

```text
fragments:       encouraged
em dashes:       avoid
headers & bold:  banned
```

## Example

Bad:

> Thank you for catching this! You're absolutely right that the previous
> implementation had an issue here. I've added your suggestion in commit `a1b2c3d`.
> This change improves both readability and maintainability of the codebase.
> Let me know if there's anything else you'd like me to address!

Good:

> Applied, thanks!
