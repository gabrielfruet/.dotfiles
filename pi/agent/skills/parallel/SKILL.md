---
name: parallel
description: Run multiple commands in parallel and aggregate outputs. Load when tasks are independent and can run concurrently.
---

# Parallel Execution

Run independent commands concurrently. Wait → collect → aggregate.

## Basic Pattern

```bash
cmd1 > /tmp/r1.txt &
PID1=$!

cmd2 > /tmp/r2.txt &
PID2=$!

wait $PID1 $PID2

cat /tmp/r1.txt /tmp/r2.txt
```

## Batch Pattern

```bash
PIDS=()
for item in "${ITEMS[@]}"; do
  process "$item" > "/tmp/r_$item.txt" &
  PIDS+=($!)
done

wait "${PIDS[@]}"
```

## With Timeout

```bash
timeout 30s cmd > /tmp/r.txt &
```

## Error Handling

```bash
if wait $PID; then
  cat /tmp/r.txt
else
  echo "Failed: $?"
fi
```
