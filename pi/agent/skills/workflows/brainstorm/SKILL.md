---
name: brainstorm
description: Use when the user runs /brainstorm <topic> to think a task through before building. Fast loop that asks every ready question in numbered rounds, each with a recommended answer; lookups run in background scouts.
argument-hint: <task or question>
disable-model-invocation: true
effort: low
---

# Brainstorm

A fast loop in rounds: ask every question that is ready, the user answers,
you ask the next round. Reply speed beats completeness. The user is mid-thought.

## Each round

```
🔎 <scout result, only if one landed>
📍 <up to 2 lines: what's settled, or a finding>

❓ **Q1 - <question title>**: <question, options if any>

➡️ <your recommended answer>, <one line of why>

---

❓ **Q2 - <question title>**: ...

➡️ ...
```

- Emojis anchor the eye: one per line type, always the same ones. No other
  decoration, no headers.
- Bold only the question number and title.
- Ask every question whose prerequisites are settled. A question that depends
  on another one still open in this round waits for the next round.
- Ask in plain text. Never use AskUserQuestion boxes.
- Always attach a recommendation to each question. Reacting is faster than
  generating.
- On a codebase topic, show code: the current state and each option as a fenced
  snippet of a few lines. Prose alone doesn't land.
- When the question is "which approach", give 2–3 options with a one-line
  tradeoff each. One is a wild card: don't build it, solve it at another
  layer, or ship half.
- Push back when the framing rests on something unverified. Agreeing fast is
  not the job.

## Facts are yours, decisions are theirs

Never ask the user something the codebase or the web can answer.

- Send a `scout` agent for any lookup beyond one small file. Put the spawn at
  the end of the turn so your text streams first.
- Don't block on it. Ask a question that doesn't depend on the result.
- When a result lands, lead the next reply with the 🔎 line:
  `🔎 scout-onnx: opset 17 covers the op, so reuse stays viable.`
  Say nothing if it changes nothing.

## Done

Stop when no open decision is left, or the user says `wrap`. Print a brief in
chat, no file:

```
🎯 <problem, one line>
✅ <decision>, <why>
❌ <rejected option>, <reason>   (one line each)
👉 <first step, small enough to start today>
```

Offer plan mode. Don't build until the user confirms.

## Start

Topic: $ARGUMENTS

With a topic: restate it sharper in one line, then ask the first question.
Send a scout if it touches the codebase. Without one: ask what we're
figuring out.
