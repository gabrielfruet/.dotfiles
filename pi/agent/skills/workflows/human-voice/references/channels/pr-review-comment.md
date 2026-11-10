# PR review comment (as reviewer)

```text
max_lines: 6
max_words: 40
rewrite: inline
voice: required
```

Reviewing someone else's code. For replying on your own PR, use
`pr-review-reply.md`.

## Shape

Three parts, in order, and nothing else:

1. The claim, in the first line.
2. The mechanism in plain words, with one concrete case ("a rank with 100
   tokens and a rank with 10 get the same weight").
3. A minimal snippet of the fix, only when the fix isn't obvious from 2.

Say so when you're not sure the case happens in practice.

The ceiling is for a finding, refactor suggestions included. Only a reply in a
design discussion the author started may run to 100 words.
Each downside names who hits it and what they see. If a cut would make the
reader ask "wdym", keep the words.

## Approval

Thank them for one thing, the way you'd say it out loud, then LGTM. Never list
several fixes in one thanks. 15–25 words.

> Thanks for adding a test for each of these. The per-annotation eye carrying the
> whole source over works for me. LGTM

## Rules

- Don't cite function or file names as evidence. The author knows their code.
  Say what happens.
- Rewriting comments the user drafted: keep their phrasing and change only the
  facts. Their openers ("We can…", "maybe…"), plain names without backticks and
  `->` arrows stay.

- No impact paragraph. No contrast example showing the correct case. No "why this
  matters" close.
- Anchor inline to the offending line, not top-level. Line numbers shift between
  pushes — verifying against the PR head is `pr-workflow`'s job, not a voice one.
- Draft in chat and wait for approval before posting.
- One claim per comment. A second claim is a second comment, or gets cut.
- One softener per comment at most: "Nit", "Not blocking", "maybe" or "your
  call", never two.
- Pass the user's own review comments to the receipt with `--voice`: their
  pending ones on this PR, else their last few in the repo.
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

Good, in the user's voice (approved):

> We can embed images, what we can't is "image bytes". This shows a wrong error,
> "cannot embed {query_kind}" -> "cannot embed images". Maybe
> `query_kind="image bytes"`? The new test matches on "cannot embed images" too,
> so it needs the same change.

> Nit: b"image bytes" reads a bit like a text value at first look. Not blocking,
> the older tests here use it too.

> Maybe we should use the MAX_INSTANCES constant here.

> I don't think we need this check. With an unknown id nothing gets deleted and
> delete() returns False anyway, so we could raise NotFoundError there instead of
> the HTTPException:
