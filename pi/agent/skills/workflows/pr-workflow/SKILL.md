---
name: pr-workflow
description: Use for any pull request work — sizing and splitting a change into PRs, opening a PR and writing its title and description, watching CI, asking someone to review, reviewing someone else's PR or branch, and answering review comments from humans or bots (CodeRabbit, Codex, Copilot). Also when new commits land on an open PR.
---

# PR workflow

Read the reference for the step you are on. Each holds that step's rules.

| Step | Read |
|---|---|
| Sizing a change, splitting into PRs or a stack, CHANGELOG | `references/scope.md` |
| Opening or updating a PR, watching CI, fixing red checks | `references/open-and-ci.md` |
| Writing the PR title and body (done by a subagent) | `references/pr-description.md` |
| Picking a reviewer and asking for review | `references/ask-review.md` |
| Reviewing someone else's PR or branch | `references/review-others.md` |
| Answering review comments on your PR | `references/address-comments.md` |

## Always

- Check size before opening a PR. Run the size check in `references/scope.md`
  and propose a split when it trips. Never open an oversized or mixed PR
  without asking.
- Never request a reviewer (`--reviewer`, `--add-reviewer`) and never name one
  in the PR body. Suggest one in chat.
- Review comments and replies are drafts for the user. Post, reply or resolve
  only when they say so.
- Review feedback never grows a PR past its purpose. Out-of-scope work becomes
  a follow-up PR, opened only after the user agrees.
- Commits follow `git-workflow`, `gh` mechanics follow `gh-cli`, and prose
  follows `human-voice`.
