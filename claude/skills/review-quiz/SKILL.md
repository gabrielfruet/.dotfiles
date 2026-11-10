---
name: review-quiz
description: "Use when the user wants to actually understand a branch, PR or diff instead of skimming it — reviewing AI-written code, \"I don't feel connected to this code\", \"help me really review this\", \"walk me into this branch\". Runs a five-step loop: calibrate what the user knows, orient them with a product view and a diagram, ask before they read the implementation, compare, then break one line and run the test."
---

# Orient, ask, compare, break

Reading a diff exercises recognition. "Looks right" is not understanding. Show
the user the shape of the change, then make them answer before they read the
implementation. That recall is what makes reviewed code stick.

Run the five steps in order, one per turn. Wait for the user between steps.

## Step 0 — Calibrate

Before anything else, list the concepts the change depends on, one per line,
plus "this codebase" and "the area this change touches". Take them from the
module the change plugs into, never from the diff's approach. Ask the user to
mark each known, vague or new. Wait. Skip it when the user already told you
this session.

## Step 1 — Orient

Show, in one turn:
- the size: commit count, files changed, lines added/removed
- what the change does from the product side, in three to five sentences: what
  a user opens, clicks or types, and what they see. With no UI, what a caller
  passes in and gets back.
- a diagram of the code the change touches and what it depends on: the render
  tree, then the state and requests behind it. Touched files in one colour,
  existing ones in grey, each box a file name plus five words or fewer. Inline
  SVG where the runtime renders it, else Mermaid.
- the runtime requirements under it: services, preconditions, limits
- the signature, params and return shape of each function the change adds

Never show function bodies. They are what step 2 asks about.

## Step 2 — Ask

Ask 3 to 5 high-level questions in one turn. Cover these, adapted to the change:
- what it lets a user do that the closest existing tool doesn't
- why its state lives where the diagram puts it, and not somewhere else
- one scenario run through several actions: "You have a prompt typed, two boxes
  drawn and results on screen. What happens to each when you (a) pan, (b) press
  Escape, (c) switch tool?"
- what must be true before the main action is allowed, and what this change did
  to that rule
- what data leaves the machine, where it goes, and where the UI says so

For a concept marked new in step 0, add one line before the question that needs
it, and nothing else. Stop and wait for the answers.

## Step 3 — Compare

Now read the diff and compare it to their answers. Report:
- a short table: their answer | right, partly or wrong | what the code does |
  `file.ts:line`
- then one paragraph on the biggest gap, and **why** the code went that way

Do not dump the diff back at them; the gaps are the content.

## Step 4 — Break one line

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
- If the branch has no tests, replace step 4 with: run the app and break the
  behaviour by hand.
- Skip the step-3 table on later runs once the habit is formed — orient, ask,
  compare, break is the whole loop.
