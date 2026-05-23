---
name: pytorch-nan-debugging
description: Use when debugging NaN/inf instability, exploding losses, or numerical collapse in PyTorch training runs.
---

# PyTorch NaN Debugging

Use this workflow to localize the *first* non-finite value, not just the final failing op.

## Triage first
- Enable `torch.autograd.set_detect_anomaly(True)`.
- Set `TORCH_SHOW_CPP_STACKTRACES=1` and `CUDA_LAUNCH_BLOCKING=1`.
- If AMP/bf16 is involved, try a full-fp32 repro or disable compile.
- Compare against a known-stable run and note the first divergent step/metric.

## Safe debug rerun
- Resume from the suspect checkpoint in a **fresh temp output dir**.
- Keep the original run directory untouched.
- If the framework resumes from `<out>/checkpoints/last.ckpt`, copy the source checkpoint there first.
- Prefer 1 GPU for the first debug rerun.

## Localize the source
- Add forward/backward hooks to suspicious modules (LayerNorm, attention, decoder heads).
- Print only the first non-finite event with: rank, step, module path, tensor kind (input/output/grad).
- Check model outputs, targets, loss terms, gradients, optimizer state, and scheduler state.

## Interpret the signal
- `detect_anomaly` identifies the failing autograd op, not always the exact module.
- A backward NaN often means the forward activation was already non-finite or numerically unsafe.
- If the failure appears only with DDP/AMP, isolate by reducing GPU count and precision.

## Bisect if needed
- Narrow the failure window by step.
- Disable suspicious augmentations or step-scheduled transforms.
- Compare stable vs failing checkpoints around the first collapse point.

## Output
Report:
- failing step/rank
- exact module path (if found)
- first non-finite tensor type
- minimal repro command
- likely root cause
