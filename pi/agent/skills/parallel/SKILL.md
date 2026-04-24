---
name: parallel
description: Run multiple commands in parallel and aggregate outputs. Load when tasks are independent and can run concurrently.
---

# Parallel Execution

Run independent commands concurrently for efficiency.

## Working Pattern (ddgs)

```bash
mkdir -p /tmp/parallel-work

(ddgs text -q "query1" -m 15 > /tmp/parallel-work/01.txt) &
PID1=$!
(ddgs text -q "query2" -m 15 > /tmp/parallel-work/02.txt) &
PID2=$!
(ddgs text -q "query3" -m 15 > /tmp/parallel-work/03.txt) &
PID3=$!
(ddgs text -q "query4" -m 15 > /tmp/parallel-work/04.txt) &
PID4=$!

wait $PID1 $PID2 $PID3 $PID4
cat /tmp/parallel-work/0*.txt
```

## Generic Pattern

```bash
mkdir -p /tmp/my-temp

(cmd1 > /tmp/my-temp/r1.txt) &
PID1=$!
(cmd2 > /tmp/my-temp/r2.txt) &
PID2=$!
(cmd3 > /tmp/my-temp/r3.txt) &
PID3=$!

wait $PID1 $PID2 $PID3
cat /tmp/my-temp/r*.txt
```

## Batch Pattern (Loop)

```bash
mkdir -p /tmp/parallel-work
PIDS=()

for item in "${ITEMS[@]}"; do
    (process "$item" > "/tmp/parallel-work/r_$item.txt") &
    PIDS+=($!)
done

wait "${PIDS[@]}"
cat /tmp/parallel-work/r_*.txt
```

## With Timeout

```bash
(timeout 60s cmd > /tmp/my-temp/result.txt) &
```

## Error Handling

```bash
(cmd > /tmp/my-temp/r.txt) &
PID=$!

if wait $PID; then
    echo "Success"
    cat /tmp/my-temp/r.txt
else
    echo "Failed with exit code: $?"
fi
```

## Guidelines

| Guideline | Reason |
|-----------|--------|
| **Use 4-6 concurrent** | Sweet spot for most systems |
| **Unique temp dir per run** | Avoids file collisions |
| **Use absolute paths** | Avoids cwd confusion |
| **Always `wait`** | Ensures all processes finish |
| **Parenthesize each bg job** | `(cmd &)` not `{ cmd & }` |

⚠️ **Critical: Use subshells for background jobs**  
Pattern `(command > output.txt) &` works reliably.  
Pattern `{ command > output.txt & }` does NOT work with ddgs.

⚠️ **Danger: Temp file race conditions**  
Never use `$$` or variable temp paths in filenames across parallel invocations.
