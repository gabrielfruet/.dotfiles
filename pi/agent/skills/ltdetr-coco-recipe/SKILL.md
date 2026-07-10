---
name: ltdetr-coco-recipe
description: Use when configuring or replicating LT-DETR v2 (ltdetrv2-s/m/l/x) COCO benchmarks via the lightly-train wrapper — model alias map, global vs per-rank batch size, recipe invariants, ECDet config mapping, cluster pins, and common gotchas.
---

## Model aliases (lightly-train pinned at `872e596`+)

| Alias (canonical) | Underlying model_name | Arch class |
|---|---|---|
| `ltdetrv2-s` (or `edgecrafter/ecvitt-ltdetr`) | `edgecrafter/ecvitt` | ViTTiny / DFINE |
| `ltdetrv2-m` (or `edgecrafter/ecvittplus-ltdetr`) | `edgecrafter/ecvittplus` | ViTTinyPlus / DFINE |
| `ltdetrv2-l` (or `edgecrafter/ecvits-ltdetr`) | `edgecrafter/ecvits` | ViTTinyPlus / DFINE |
| `ltdetrv2-x` (or `edgecrafter/ecvitsplus-ltdetr`) | `edgecrafter/ecvitsplus` | ViTTinyPlus / DFINE |

The m/l/x all share the same HybridEncoder / DFINE Transformer / ECViT-backbone-wrapper class — only the backbone weights file differs. The `ltdetrv2-{s,m,l,x}-coco` aliases (and `edgecrafter/ecvitt-ltdetr-coco`) auto-download a COCO-pretrained checkpoint; the bare aliases do not.

## Batch size: GLOBAL, not per-rank

`lightly-train`'s `--batch-size` is the **GLOBAL** (summed over DDP ranks) batch size, NOT per-rank. With `--ntasks-per-node=2` each rank gets 16 imgs/step. `STEPS_PER_EPOCH = train_imgs / batch_size` (118287 / 32 = 3696 for COCO train2017). LR (e.g. 5e-4) is tuned for the global effective bs.

**Recipe invariant:** if you must reduce per-rank memory, drop augs (`--no-copyblend` first, then `--no-mosaic`, then `--no-mixup`) BEFORE touching `--batch-size`. The local `train.py` wrapper does not currently expose `--accumulate-grad-batches` / `gradient_accumulation_steps`; MLflow logs show `gradient_accumulation_steps=1` for these runs. Halving `--batch-size` without accumulation silently changes the effective optimizer batch and invalidates the mAP comparison. If the wrapper is extended to expose accumulation, a possible memory-preserving retry is global microbatch 16 + accumulate 2, but verify the resolved config first: effective optimizer batch must remain 32, and step/epoch-derived aug, validation, checkpoint, and scheduler boundaries must still match the intended recipe.

## Per-variant recipe constants (EdgeCrafter config mapping)

| Setting | `ltdetrv2-s` (Tiny, ECDet-S) | `ltdetrv2-m` (Tiny+, ECDet-M) | `ltdetrv2-l` (Small, ECDet-L) |
|---|---:|---:|---:|
| Epochs | 74 | 62 | 50 |
| Total steps (bs=32, 3696/ep) | 273504 | 229152 | 184800 |
| LR | 5e-4 | 5e-4 | 5e-4 |
| Backbone LR factor | 0.05 | 0.05 | 0.01 |
| Weight decay | 1e-4 | 1e-4 | 1.25e-4 |
| Mixup + mosaic prob | 0.75 | 0.75 | 1.0 |
| Mosaic stop epoch | 36 | 30 | 24 |
| Strong-aug stop epoch | 72 | 60 | 48 |

For `ltdetrv2-x` (Small+): no ECDet-X reference exists; mirror `ltdetrv2-l` (same decoder arch class, only backbone weights differ). Revisit if a separate X reference appears.

## Staged-aug start (~4 epoch warmup)

`AUG_START_STEPS = 15000` (≈ epoch 4). Photometric / random zoom-out / random IoU crop, mixup, mosaic, copyblend all turn on at step 15000. Resolved LR schedule (from `.err` config-dump): warmup 8ep / flat 38ep / no-aug 10ep / cosine; LR target reached at epoch 8. `--no-scale-jitter` matches the ECDet recipe (best-6x uses scale-jitter instead).

## Cluster (compute-03-ubuntu-4x4090, User lightly)

- `sinfo -p debug`: `TIMELIMIT=infinite`, `gpu:4` capacity. Walltime is NOT a job killer.
- `sacct` is **disabled**. Detect job exit via `/logs/.../*.err` + squeue job absence, NOT sacct.
- `/home/lightly/lt_detr_jobs/` is per-job scratch — NOT reliably visible from login context after the job ends. Persist run metadata (`mlflow_run_id.txt`, log tails) to a stable path before the job exits.
- Two `ltdetrv2-{m,l,x}` jobs (each `--gres=gpu:2`) fit concurrently on the 4-GPU node. Submit in order; Slurm schedules PENDING→RUNNING back-to-back.
- `TORCH_NCCL_ASYNC_ERROR_HANDLING=1` + `TORCH_NCCL_DUMP_ON_TIMEOUT=1` in the job env prevent the 30-min NCCL watchdog hang and zombie GPU-context leaks seen on prior runs.

## Gotchas

- `train.py` forces `mixup` / `mosaic` / `copyblend` to `None` unless you pass `--mixup --mosaic --copyblend` (opt-in). Photometric / random zoom-out / random IoU crop / random flip / scale-jitter are `--no-*` opt-out. Easy to silently lose all three augs after a config round-trip.
- Grep `oom` / `error` / `cancel` over `.err` matches legitimate config-dump keys (`random_zoom_out`, `scheduler_no_aug_steps`, `<Config CANCELLED at ...>`). Use `squeue -j $JID` returning empty as the crash check; reserve `.err`-grep for milestone keywords only.
- Step math ≠ epoch math: 3696 steps/ep only after the resolved config is correct. Always cross-check against the `.err`-printed resolved config before reasoning about aug timings.
