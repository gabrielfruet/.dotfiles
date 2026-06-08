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
10. After submission, wait before judging the job; check `squeue`, `scontrol show job <id>`, and logs on the cluster. If `InvalidAccount` appears immediately, re-check after a short delay before assuming the submission is final.
11. If the job fails quickly, inspect stderr first for missing tools, auth issues, or repo/commit mismatch.

## Common checks

- `ssh <host> 'squeue -u <user>'`
- `ssh <host> 'tail -n 100 <logfile>'`
- `ssh <host> 'git -C <repo> rev-parse HEAD'`
- `ssh <host> 'command -v uv || command -v python3.13'`
