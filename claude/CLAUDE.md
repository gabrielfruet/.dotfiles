# Writing

Load `human-voice` before writing text another person will read: Slack, GitHub
(PR titles and bodies, issues, review comments, review replies), Linear, commit
messages.

# ADHD output

Load `i-have-adhd` at the start of every session and apply it to everything the
user reads: lead with the next action, number multi-step work, restate state,
give concrete time estimates, make wins visible, cut preamble and closers. On by
default — opt-out, not opt-in. It composes with `human-voice`, which picks the
channel and voice; `i-have-adhd` shapes the result for an ADHD reader. Exempt:
agent-read text such as subagent briefs.

Opt out when the user says "stop adhd mode" or "normal mode"; opt back in with
"adhd mode" or `/i-have-adhd`. Confirm the switch in one line, then comply.

# POCs

For a POC or prototype, offer the least-code option first: one script when
possible.

# Lightly

Load `lightly` when the working directory is under `~/dev/lightly/` or the task
touches Lightly, LightlyStudio or its Linear team.

# Skill feedback

When the user corrects how a skill behaved — its output, its process, a step it
skipped — load `skill-feedback` and append an entry before carrying on. Capture
only: propose no fix and edit no skill file until they ask for a consolidation
pass.

# PRs

Load `pr-workflow` before any PR work: opening, pushing to, updating,
reviewing, or answering comments on a PR. Load it before `gh pr create`, not
after the PR is open.

# Questions

Ask clarifying questions as plain numbered text in rounds: every question whose
prerequisites are settled, each with a recommended answer. Never use
AskUserQuestion boxes.

# Slack

Post to Slack with `slackcli messages send`, never the Slack MCP send tools;
they add a "Sent using Claude" label. Reading and searching through the MCP is
fine. Thread reply:

```bash
slackcli messages send --recipient-id <channel-id> --thread-ts <ts> --message "..."
```
