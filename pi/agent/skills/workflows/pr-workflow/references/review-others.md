# Reviewing someone else's PR or branch

1. `git fetch --all --prune`, every time.
2. Given a PR number, read the PR itself: `gh pr view <n>`, `gh pr diff <n>`.
3. Working from local refs, range against `origin/<base>` and confirm it is
   current: `git rev-list --count HEAD..origin/<base>` should print 0. No
   upstream configured means you name the base by hand, never that you fall
   back to the local copy.
4. State the resolved base with its commit in the review:
   `origin/master@a1b2c3d...HEAD`.
5. In a stack, check the downstream branches before reporting a finding
   (`git log <this>..<downstream> -- <path>`). A finding a later PR fixes is
   not reported. At most, note which branch fixes it.
6. Put every comment in one review, submitted in a single call:
   `gh api repos/<owner>/<repo>/pulls/<n>/reviews --input review.json`, with a
   `comments` array. "Comment" in the user's request names the content, never
   the standalone-comment endpoint.

Comment wording follows `human-voice`.
