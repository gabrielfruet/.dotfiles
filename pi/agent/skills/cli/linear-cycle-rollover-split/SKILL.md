---
name: linear-cycle-rollover-split
description: Use at Linear cycle rollover to split every unfinished issue assigned to the user across the cycle boundary — credit each issue's completed story points to the closing cycle and carry the remainder into the next. Sweeps all the user's in-progress/in-review issues in one pass; the only per-issue input is the completed points.
---

# Linear cycle rollover split

When a cycle ends, split every unfinished issue assigned to the user so velocity
reflects what shipped: the completed points stay in the closing cycle `N`, the
rest carry to `N+1`. Runs over all the user's issues at once — the only input per
issue is `X`, the points completed. Load the `linear-cli` skill for CLI mechanics.

## Procedure

1. List the user's started issues in the active (closing) cycle `N`:
   ```bash
   linear api <<'Q'
   query{issues(filter:{
     assignee:{isMe:{eq:true}},
     cycle:{isActive:{eq:true}},
     state:{type:{eq:"started"}}
   }){nodes{identifier title estimate team{key} project{name} cycle{number} state{name}}}}
   Q
   ```
2. Drop any issue with estimate `E = 0` (unestimated, or already split). If none
   remain, report "no eligible issues" and stop.
3. Render one row per issue and ask for `X` in a single pass:
   ```text
   #  ID          Title                          E   State        X (done)
   1  LIG-10501   Add dark mode toggle            5   In Progress  ?
   2  LIG-10502   Fix flaky embedding test        3   In Review    ?
   ```
   Ask: "reply with N numbers, space-separated, in row order — points finished
   this cycle (each ≤ E)". Nothing else is needed.
4. Echo the plan back per issue (`#1: 3 done in N, 2 carry to N+1`) and get a
   confirm before touching anything.
5. For each issue, with `R = E - X`, run the split:
   ```bash
   # done half — stays in cycle N
   linear issue create --team <KEY> --parent <ID> --project "<PROJECT>" \
     --assignee self --cycle <N> --estimate <X> --state Done \
     --title "<TITLE> (Cycle <N>)"
   # carry half — only if R > 0
   linear issue create --team <KEY> --parent <ID> --project "<PROJECT>" \
     --assignee self --cycle <N+1> --estimate <R> --state Todo \
     --title "<TITLE> (Cycle <N+1>)"
   # zero the parent so points don't double-count
   linear issue update <ID> --estimate 0
   ```
6. Verify estimate, state, cycle and parent on every issue touched, then report
   the results as a table.

## Rules
- `E = 0` → skip in step 2 (already split, or unestimated).
- `X = 0` → skip the split; the issue rolls over whole.
- `X = E` → `R = 0`: create only the done half, no carry.
- Both sub-issues inherit the parent's team, project and assignee.
- The parent keeps its state; only its estimate drops to 0.
- Always confirm the full `X` list (step 4) before creating anything.
