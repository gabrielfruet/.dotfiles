---
name: linear-cycle-rollover-split
description: Use at Linear cycle rollover to split every unfinished issue assigned to the user across the cycle boundary — credit each issue's completed story points to the closing cycle and carry the remainder into the next. Works both just before the boundary and just after it. Sweeps all the user's in-progress/in-review issues in one pass; the only per-issue input is the completed points.
---

# Linear cycle rollover split

When a cycle ends, split every unfinished issue assigned to the user so velocity
reflects what shipped: the completed points stay in the closing cycle, the rest
carry to the cycle after it. Runs over all the user's issues at once — the only
input per issue is `X`, the points completed.

The split can run on either side of the boundary, so first decide which pair of
cycles it spans:

- `D` — the done cycle, which gets the completed points.
- `C` — the carry cycle, which gets the remaining points.

## Setup

Needs the [Linear CLI](https://github.com/schpet/linear-cli?tab=readme-ov-file#install)
on PATH and authenticated (`linear auth login`). Check with `linear --version`, or
prefix every command with `npx @schpet/linear-cli` instead of `linear`.

## Procedure

1. List the user's started issues in the active cycle, plus the cycles around it:
   ```bash
   linear api <<'Q'
   query{issues(filter:{
     assignee:{isMe:{eq:true}},
     cycle:{isActive:{eq:true}},
     state:{type:{eq:"started"}}
   }){nodes{identifier title estimate team{key} project{name} cycle{number} state{name}}}}
   Q
   linear api <<'Q'
   query{cycles(filter:{team:{key:{eq:"<KEY>"}}, or:[
     {isPrevious:{eq:true}}, {isActive:{eq:true}}, {isNext:{eq:true}}
   ]}){nodes{number startsAt endsAt isPrevious isActive isNext}}}
   Q
   ```
   Linear moves unfinished issues into the new cycle at the boundary, so the
   active cycle holds them on both sides of it.
2. Pick `D` and `C` from where now falls in the active cycle `A`:
   - Closer to `startsAt` (the cycle just began) → `D = A - 1`, `C = A`.
   - Closer to `endsAt` (the cycle is about to end) → `D = A`, `C = A + 1`.

   Compare in UTC against the timestamps, not against local dates. Linear
   accepts an ended cycle as `--cycle`, so `D = A - 1` works as is.
3. Drop any issue with estimate `E = 0` (unestimated, or already split). If none
   remain, report "no eligible issues" and stop.
4. State the pair with its dates, render one row per issue, and ask for `X` in a
   single pass:
   ```text
   Splitting 125 (Sep 2–15, done) → 126 (Sep 15–29, carry). Cycle 126 started yesterday.

   #  ID          Title                          E   State        X (done)
   1  LIG-10501   Add dark mode toggle            5   In Progress  ?
   2  LIG-10502   Fix flaky embedding test        3   In Review    ?
   ```
   Ask: "reply with N values, space-separated, in row order — points finished
   in cycle `D` (each ≤ E), or `-` to leave an issue unsplit". The user can
   override the pair in the same reply.
5. Echo the plan back per issue (`#1: 3 done in D, 2 carry to C`,
   `#2: not split`) and get a confirm before touching anything.
6. For each issue not marked `-`, with `R = E - X`, run the split:
   ```bash
   # done half — only if X > 0
   linear issue create --team <KEY> --parent <ID> --project "<PROJECT>" \
     --assignee self --cycle <D> --estimate <X> --state Done \
     --title "<TITLE> (Cycle <D>)"
   # carry half — only if R > 0
   linear issue create --team <KEY> --parent <ID> --project "<PROJECT>" \
     --assignee self --cycle <C> --estimate <R> --state Todo \
     --title "<TITLE> (Cycle <C>)"
   # zero the parent so points don't double-count
   linear issue update <ID> --estimate 0
   ```
7. Verify estimate, state, cycle and parent on every issue touched, then report
   the results as a table.

## Rules
- `E = 0` → skip in step 3 (already split, or unestimated).
- `-` → no split; the issue rolls over whole with its estimate.
- `X = 0` → still split: create only the carry half with `R = E`, and zero
  the parent.
- `X = E` → `R = 0`: create only the done half, no carry.
- Both sub-issues inherit the parent's team, project and assignee.
- Parent has no project → drop `--project` from both `create` calls.
- The parent keeps its state and cycle; only its estimate drops to 0.
- Never pick `D` from the issue's `cycle{number}` alone. After the boundary it
  already shows the new cycle, which is the carry cycle.
- Always confirm the pair and the full `X` list (step 5) before creating anything.

## Fixing a split in the wrong cycles

Move each sub-issue and rename it to match, after the user confirms a
before/after table:

```bash
linear issue update <SUB_ID> --cycle <D> --title "<TITLE> (Cycle <D>)"
linear issue update <SUB_ID> --cycle <C> --title "<TITLE> (Cycle <C>)"
```

Leave the parent alone. Verify as in step 7.
