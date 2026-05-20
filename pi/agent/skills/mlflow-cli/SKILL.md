---
name: mlflow-cli
description: Use when analyzing remote MLflow tracking servers from the CLI to inspect experiments, runs, metrics, params, tags, and artifacts.
---

# MLflow CLI

- Remote-first: assume `MLFLOW_TRACKING_URI` points to the target server; if it is missing, ask for the server URL before querying.
- Prefer the installed MLflow `--help` / subcommand help first; use docs only to fill gaps.
- If `mlflow` is not available, try the project environment (`uv run mlflow --help` or `.venv/bin/mlflow --help`) before giving up.
- If MLflow is still unavailable, stop and report this to the user instead of silently falling back to another API/client.
- Read-only only: use search/list/describe/export/download. Do not create, delete, restore, serve, or deploy.
- Prefer `--output json` where supported and `mlflow experiments csv` for comparisons.

## Workflow
1. Find the experiment with `mlflow experiments search`, then confirm it with `mlflow experiments get -x <id>` or `-n <name>`.
2. Inspect runs with `mlflow runs list --experiment-id <id>`; use `--view active_only|deleted_only|all` when needed.
3. Describe candidate runs with `mlflow runs describe --run-id <run_id>` to capture params, metrics, tags, artifact roots, and metric history context.
4. Inspect artifacts with `mlflow artifacts list -r <run_id> [-a <path>]`, then download interesting paths with `mlflow artifacts download`.
5. Export the full run table with `mlflow experiments csv -x <id> -o <file>` for offline sorting/comparison.
6. If the run is/was launched on Slurm, compare MLflow status with the live job state before concluding.

## What to extract
- best metrics and the run IDs that achieved them
- final metrics and the gap to best metrics
- metric history shape: steady rise, plateau, peak+decay, or collapse
- runtime/perf: throughput, step time, GPU util, GPU memory, total time
- run completeness: finished, truncated, or still running
- key hyperparameters and data/version tags
- artifact files that explain behavior (`MLmodel`, `requirements.txt`, `conda.yaml`, plots, checkpoints, logs)
- repeated patterns across runs that suggest what changed

## Style
- Summarize findings succinctly.
- Call out missing tracking URI or missing experiment/run IDs immediately.
- If the user wants deeper model execution, stop here and ask before using non-read-only MLflow commands.
