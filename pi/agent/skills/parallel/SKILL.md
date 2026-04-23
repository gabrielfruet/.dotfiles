---
name: parallel
description: Run multiple commands in parallel and aggregate outputs. Load when tasks are independent and can run concurrently.
---

# Parallel Execution

Run independent commands concurrently.

⚠️ **Danger: Temp file race conditions**  
When running commands that use temp files (like `ddgs`), ensure they write to a **dedicated temp directory** (e.g., `/tmp/agent-research/`), not the current working directory. Variable temp paths or `$$` in filenames cause pollution across parallel invocations.

## Basic Pattern

```bash
mkdir -p /tmp/my-temp
{
    cmd1 > /tmp/my-temp/r1.txt &
    PID1=$!
    cmd2 > /tmp/my-temp/r2.txt &
    PID2=$!
} &
PIDS+=($!)
wait $PID1 $PID2
cat /tmp/my-temp/r1.txt /tmp/my-temp/r2.txt
```

## Batch Pattern

```bash
mkdir -p /tmp/my-temp
PIDS=()
for item in "${ITEMS[@]}"; do
    process "$item" > "/tmp/my-temp/r_$item.txt" &
    PIDS+=($!)
done
wait "${PIDS[@]}"
cat /tmp/my-temp/r_*.txt
```

## With Timeout

```bash
timeout 30s cmd > /tmp/my-temp/result.txt &
```

## Error Handling

```bash
if wait $PID; then
    cat /tmp/my-temp/r.txt
else
    echo "Failed: $?"
fi
```

## Web Search (ddgs) Pattern

```bash
mkdir -p /tmp/agent-research
{
    ./web-search.sh "query1" > /tmp/agent-research/s1.txt &
    ./web-search.sh "query2" > /tmp/agent-research/s2.txt &
} &
PIDS+=($!)
wait $PIDS
cat /tmp/agent-research/s1.txt /tmp/agent-research/s2.txt
```
