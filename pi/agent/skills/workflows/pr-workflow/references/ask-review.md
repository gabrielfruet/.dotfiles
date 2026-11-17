# Asking for review

- Pick the reviewer from `git log` of the changed files: whoever changed them
  most recently. Confirm they can still review, since departed authors keep their
  commits:
  `gh api repos/<owner>/<repo>/collaborators --jq '.[].login'`.
  Drop anyone the user ruled out.
- Use one reviewer for the whole stack.
- Open every PR of a stack as a draft, because each ready PR runs the full CI.
  Mark one ready (`gh pr ready <n>`) only when its wave goes out.
- Ask in waves. Wave 1 is the bottom 2-3 PRs holding the decisions a reviewer
  can push back on (spec, API shape, the core rule). Ask for the rest once wave 1
  is approved.
- Skip PRs the repo's fast-track bot already approved.
- Add screenshots to a GUI PR's body before asking.
- Show the plan (reviewer, waves, why) and the exact text of every comment and
  message. Send only after the user says yes.
- lightly-ai/lightly-studio: the ask goes through PR Bot and a Slack thread.
  See the `lightly` skill, `references/studio-review.md`.
