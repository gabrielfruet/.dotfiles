---
name: codepath-debugging
description: Use when debugging a traceback, runtime error, unexpected behavior, value/config mismatch, tensor/data shape issue, or when the user asks to backtrack where variables come from and where they go.
---

# Codepath Debugging

Use this skill to trace runtime failures or suspicious values back to the smallest root cause without modifying the repository.

## Rules
- Do not edit, write, scaffold, or refactor project code.
- Confirm the active checkout first (`pwd`, `git rev-parse --show-toplevel`, and `git status --short`).
- Start at the exact failure/observation site, then walk backward through callers until the relevant value/config/input is created.
- Prefer evidence over guesses: cite file paths, functions/classes, line numbers, and concrete values.
- If instrumentation is needed, propose it as temporary debug code or commands, but ask before modifying files.

## Process
1. Reconstruct the failing path from traceback/log/user report.
2. Identify the immediate invariant violation: shape mismatch, type mismatch, wrong branch, stale config, unexpected value, etc.
3. Build a ledger for important variables: name, origin, transformation, concrete value/shape, and next consumer.
4. Trace config separately from data flow: API/CLI args → config models → constructors → module attributes → runtime use.
5. Compare failing vs working case and isolate the first divergent value.
6. Substitute real numbers early; track rounding and boundary behavior (`//`, `int`, stride, padding, resize, batching, concat, joins, filters).
7. Form 2-3 falsifiable hypotheses and state what would prove/disprove each.
8. Prefer minimal repro commands or tiny synthetic inputs over full end-to-end runs.

## ML/PyTorch notes
- Track tensor shapes through dataset → transform → collate → model → loss.
- Check train/eval mode, dtype/device, batch-level augmentations, random resizing, padding/divisibility, and floor/ceil behavior.
- Useful formulas: conv/pool output is `floor((in + 2*pad - dilation*(kernel-1) - 1) / stride + 1)`; stride-2 `kernel=3,padding=1` gives `ceil(in/2)`.

## Output
1. Relevant codepath summary
2. Variable/value ledger with concrete numbers
3. Working vs failing comparison
4. Ranked hypotheses
5. Minimal workaround and robust fix direction
6. Suggested validation or instrumentation
