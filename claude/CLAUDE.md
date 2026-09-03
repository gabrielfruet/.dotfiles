# Writing

Loading `human-voice` is mandatory before writing any prose: Slack, GitHub (PR
titles and bodies, issues, review comments, review replies), Linear, commit
messages, plan files, and every response handed back in chat. Read its routing
table, load the matching channel file, then write. Not conditional on being
asked, and staying in chat is not an exemption.

# ADHD output

Load `i-have-adhd` at the start of every session and apply it to everything the
user reads: lead with the next action, number multi-step work, restate state,
give concrete time estimates, make wins visible, cut preamble and closers. On by
default — opt-out, not opt-in. It composes with `human-voice`, which picks the
channel and voice; `i-have-adhd` shapes the result for an ADHD reader. Exempt:
agent-read text such as subagent briefs.

Opt out when the user says "stop adhd mode" or "normal mode"; opt back in with
"adhd mode" or `/i-have-adhd`. Confirm the switch in one line, then comply.

# Plan Mode

When entering plan mode (via `EnterPlanMode` or when asked to "plan" something),
always load both the `plan-mode` and `human-voice` skills at the start, in addition
to any other skills the task needs. Apply `plan-mode`'s rules throughout the
planning phases, and apply `human-voice`'s `ai-facing` channel and `i-have-adhd`
to the final plan text before writing it to the plan file.

# Skill feedback

When the user corrects how a skill behaved — its output, its process, a step it
skipped — load `skill-feedback` and append an entry before carrying on. Capture
only: propose no fix and edit no skill file until they ask for a consolidation
pass.
