# Commit message

```text
max_lines: 5
max_words: 50
rewrite: inline
```

For staging, diff review and per-commit hygiene, defer to `git-workflow`.

## Shape

Imperative subject, one line if possible. Body only when the *why* is not obvious
from the diff, separated by a blank line.

```text
Fix off-by-one in crop selector

Sorting was assuming x1 < x2, which holds for every caller except
the augmentation path.
```

## Rules

- Imperative mood: "Fix off-by-one in crop selector", not "This commit fixes an
  off-by-one error in the crop selector logic".
- The subject says what changed, not that a change happened.
- No internal links or ticket IDs (`TRN-1234`, Notion, Slack). Same rule as the
  PR title, for the same reason: those links rot and the commit is permanent.
- If a ticket ID slips into a pushed commit, reword and force-push the feature
  branch before the PR is reviewed.

## Allowed here

```text
fragments:       n/a (the subject is already a fixed imperative form)
em dashes:       banned
headers & bold:  banned
```

## Example

Bad:

> This commit updates the configuration loading logic to handle Path objects in
> addition to strings, which improves the flexibility of the API and makes it
> more consistent with the rest of the codebase.

Good:

> Accept Path in load_config()
