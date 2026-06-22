---
name: remote-slurm-bootstrap
description: Use when submitting, monitoring, or fixing Slurm benchmark jobs on a remote cluster; always work on the cluster host via SSH, sync files first, bootstrap the env if needed, and keep benchmark code simple and readable.
---

## Purpose

Cluster-first workflow for benchmark jobs.

## Rules

0. If the hostname does not resolve, check `~/.ssh/config` for the actual SSH alias before assuming the host is unavailable.
1. Always do the work on the target cluster host via SSH.
2. If local Slurm tools are missing, do not switch to local execution.
3. Sync changed files to the cluster before submitting.
4. If possible, sync through git on the cluster repo/worktree; if not, use `rsync`/`scp`.
5. Prefer an existing remote repo checkout or worktree over cloning inside the job. If other experiments are running on the same host, use a dedicated worktree and never run job-time `git checkout` commands against a shared checkout.
6. If a pinned commit is needed, verify it exists in the remote checkout before launch.
7. Prefer `uv` if it already exists on the cluster.
8. If `uv` is unavailable, use `python3.13` + `python -m venv` + `python -m pip`.
9. Keep benchmark scripts explicit and readable; avoid clever abstractions.
10. **Polling discipline.** Each `ssh` round-trip costs model tokens. Plan the sleep, then do the least number of polls possible.
    - **Before submission:** estimate expected duration of the command you're about to run (env bootstrap, pip install, training checkpoint interval, etc.) and pick a `sleep` that lands at the next meaningful event. Never poll right before a checkpoint boundary you already know is coming.
    - **One sleep, one combined poll.** Use a single bash call: `sleep N && ssh <host> 'squeue -j <id> -o "%i %T %M %N %R"; scontrol show job <id> | grep -E "JobState|Reason|NodeList|ExitCode"; tail -n N <logfile>; find <out_dir> -type f'`. `N` should be ≥ 2× the expected per-step duration, longer for pip installs and engine builds.
    - **Do not poll without sleeping first.** A bare `ssh ... squeue` with no sleep wastes a round-trip — you already know the state from the previous poll.
    - **Only re-poll when something should have changed:** a new validation window, a job that was PENDING and might have started, or a job past its expected end time.
    - An immediate `InvalidAccount` or other quick failure warrants one short re-check, not continuous polling.
11. If the job fails quickly, inspect stderr first for missing tools, auth issues, or repo/commit mismatch.

## Common checks

- `ssh <host> 'squeue -u <user>'`
- `ssh <host> 'tail -n 100 <logfile>'`
- `ssh <host> 'git -C <repo> rev-parse HEAD'`
- `ssh <host> 'command -v uv || command -v python3.13'`
- One combined poll (preferred for long jobs): `sleep <planned> && ssh <host> 'squeue -j <id> -o "%i %t %M %N %R"; scontrol show job <id> | grep -E "JobState|Reason|NodeList|ExitCode"; tail -n 80 <logfile>; find <out_dir> -type f'`

## Polling cadence cheat sheet

| Event you're waiting for | Suggested sleep before the next poll |
|---|---|
| Job to leave PENDING and start running | 2–5 min |
| Next validation window (known step interval) | `val_every_num_steps × step_time` (e.g. 3750 steps × 0.24 s ≈ 15 min) |
| Pip install / venv setup (first job on fresh env) | 5–10 min |
| Long training run, just want a sanity check | 30–60 min |
| Job past its expected end | 5–10 min, then a final poll |
