# Scope and size

A PR is reviewable in one sitting. What sets the limit is how much existing
logic it changes, because the reviewer must hold the old behavior in their head.

## Size check

Run it before opening a PR and before every new commit on a feature branch:

```bash
base=origin/main   # the PR's actual base
git diff --numstat --diff-filter=M $base...HEAD | awk '{s+=$1+$2} END{print "modified", s+0}'
git diff --numstat --diff-filter=A $base...HEAD | awk '{s+=$1} END{print "added", s+0}'
```

Propose a split and stop when any of these is true:

- More than 200 modified lines (adds + deletes in files that already existed).
- More than 500 lines in new files.
- A refactor (rename, move, extract) and a behavior change on the same branch.

## Splitting

- One PR, one kind of change. A PR that adds a lot but rewires call sites is
  modificatory, not additive.
- A prep refactor is its own PR, decided before its first commit: commit it on
  its own branch, push, and stack the feature on top.
- Ask before splitting and ask before opening a combined PR. Never do either
  silently.
- In repos you control, stack the PRs. In an external OSS repo, ship separate
  sequential PRs instead.
- A modificatory PR that can't be split says why in the description and keeps
  commits separable, so the reviewer can go commit by commit.
- A prototype gets no PR unless asked, and then one PR, never a stack.

## CHANGELOG

One entry per feature, not per PR. In a stack the first PR adds it and later
PRs edit it. Describe what users see change. A data migration is never "Fixed".
A separate user-visible effect, such as a speedup, gets its own line.
