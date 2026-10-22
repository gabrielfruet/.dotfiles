---
name: review-blind
description: "Use when the user wants to actually understand a branch, PR or diff instead of skimming it — reviewing AI-written code, \"I don't feel connected to this code\", \"help me really review this\", \"walk me into this branch\". Runs a four-step loop: calibrate what the user knows, predict before reading, compare, then break one line and run the test."
---

# Predict, read, break

Reading a diff exercises recognition. "Looks right" is not understanding. This
skill forces recall and effort instead, which is what makes reviewed code stick.

Run the four steps in order, one per turn. Wait for the user between steps.

## Step 0 — Calibrate

Before any prediction, list the concepts the change depends on, one per line,
plus "this codebase" and "the area this change touches". Take them from the
module the change plugs into, never from the diff's approach. Ask the user to
mark each known, vague or new. Wait. Skip it when the user already told you
this session.

## Step 1 — Predict

Do **not** show the diff, the file names, the commit subjects or the stat. Showing
any of them ends the exercise.

Give the user only:
- the goal of the change, in one sentence (ticket title, PR title)
- the size: commit count, files changed, lines added/removed
- two or three lines on what the surrounding system already does: the module
  the change plugs into, the convention it follows. Never the diff's own files
  or its approach.

Then ask one question per decision the change makes, as many as the user needs
to build their own model of it, one line each. Shape them from step 0: for each
concept the user marked vague or new, explain it in one line before the question
that needs it. Never explain the diff's approach. For example:
- Where does the central state live?
- What drives the main behaviour, and what turns it off?
- Which edge case breaks first?

Adapt the wording to the change. Stop and wait for their answers.

## Step 2 — Read

Now read the diff and compare it to their answers. Report:
- a short table: their guess | what the code does | right or missed
- then one paragraph on the biggest gap, and **why** the code went that way

Link every claim to `file.ts:line`. Do not dump the diff back at them; the gaps
are the content.

## Step 3 — Break one line

Pick a line that carries a **decision**, not a mechanism:
- a guard or early return (someone hit a bug and left a fence)
- a magic number or a fallback path
- a line whose comment explains *why*

Skip any line whose failure is obvious in advance. If you can predict the failure
with certainty, so can they, and nothing is learned.

Then:
1. Tell them the line and the test command
2. Ask them to guess which test fails **before** running it
3. Run it, confirm or correct, restore the file

Always restore. Back the file up first and copy it back in the same command.

## Rules

- Never front-run a step. The value is entirely in the user answering first.
- One branch per run, ~10 minutes total.
- If the branch has no tests, replace step 3 with: run the app and break the
  behaviour by hand.
- Skip the step-2 table on later runs once the habit is formed — predict, read,
  break is the whole loop.
