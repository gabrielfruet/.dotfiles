# PR description

```text
max_lines: 20
max_words: 200
rewrite: flagger + rewriter
```

The single home for PR-body guidance: gather the diff and commits, then shape
them. The draft hands off to `pr-workflow`, which owns `gh pr create/edit`.

## Gather

Run in a subagent when one is available — if you already know why the change was
made without reading `git log`, you are the wrong context to write the
description, and it shows up as detail no reviewer asked for.

1. Base: `git merge-base HEAD origin/main` (or the PR's actual base branch).
2. Changes: `git diff <base>...HEAD`
3. Intent: `git log <base>..HEAD` — full bodies, not `--oneline`; commit messages
   carry the "why" the diff can't show.
4. If `.github/pull_request_template.md` exists, fill *that* structure instead of
   the shape below.

## Shape

Skip any section that adds no signal. A short PR is one summary line, not an
empty template.

1. **Summary** — 1-3 sentences: what the PR accomplishes and the approach taken.
   Not a commit-by-commit changelog; the diff is the changelog.
2. **Changes** — bullets grouped by area (`api/`, `tests/`, config), not per
   commit. One line each, intent rather than mechanics.
3. **Breaking changes** — only when a public API, config key or CLI flag changed.
   Name old to new, and the migration.
4. **Testing** — commands run, cases covered. Omit if trivial.

## Rules

- Length tracks diff size. A one-file config change gets a paragraph and a
  testing line; a new subsystem earns the full shape.
- Altitude over completeness. A reviewer reads the summary, not every bullet.
- The title makes the same claim as the Summary, compressed to one line. Name the
  approach, not the ticket ID. If the approach shifts, title and summary shift together.
- No internal or private links anywhere in the PR, including the title and any
  commit messages: Notion, Linear IDs like `TRN-1234`, Slack threads. Applies
  whether or not the repo is public; internal tools get renamed and the links rot.
  Say the "why" in prose, or link a public GitHub issue.
- Don't quantify a change you didn't make. `235 lines across 16 files` for a diff
  you split away is a projection, not a measurement: the reader can't verify it
  and doesn't need it. For a stacked PR, say the split isolates the behavior
  change, and drop the would-be size.

## Allowed here

```text
fragments:       sparing
em dashes:       banned
headers & bold:  only if the repo template requires them
```

## Example

Bad:

> This PR introduces a comprehensive refactoring of the crop selection logic. I
> have updated `select_crop()` to sort coordinates before comparison, which
> significantly improves the robustness of the bounding box handling. I also
> added tests. Let me know if you have any questions!

Good:

> Degenerate boxes were slipping through when `x2 < x1`. Sorting the coords at
> the top of `select_crop()` fixes it without touching the caller.
>
> Testing: `pytest tests/test_crop.py`, plus a case for the inverted box.
