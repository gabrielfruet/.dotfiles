# PR review comment (as reviewer)

```text
max_lines: 6
max_words: 60
rewrite: rewriter
```

Reviewing someone else's code. For replying on your own PR, use
`pr-review-reply.md`.

## Shape

Three parts, in order, and nothing else:

1. The claim, in the first line.
2. One sentence of mechanism.
3. A minimal snippet of the fix.

## Rules

- No impact paragraph. No contrast example showing the correct case. No "why this
  matters" close.
- Anchor inline to the offending line, not top-level. Line numbers shift between
  pushes — verifying against the PR head is `pr-workflow`'s job, not a voice one.
- Draft in chat and wait for approval before posting.
- Assume the first draft is 2-3x too long. Write the short version instead of
  trimming a long one.
- Scope is a separate question from voice: confirm the PR introduced the code
  before commenting on it. `pr-workflow` owns that check.

## Allowed here

```text
fragments:       ok
em dashes:       avoid
headers & bold:  banned
```

## Example

Bad:

> I noticed that this loop iterates over the full list on every call. While this
> works correctly for small inputs, it could potentially become a performance
> bottleneck as the dataset grows. Consider using a set for O(1) lookups instead.
> For reference, the pattern used in `loader.py` handles this correctly. This
> matters because the function is on the hot path.

Good:

> `seen` is a list, so this is O(n²) on the hot path.
>
> ```python
> seen = set()
> ```
