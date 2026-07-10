# pi-watch — Non-blocking Job Watchers (Design)

> Reactive layer for pi: the agent launches non-blocking watchers that wake the
> conversation when an async job finishes. Monitor CI, wait for a training run,
> wait for long-running code — **without blocking the agent turn.**

## Context

pi can already be reactive — it's an **ergonomics gap, not a capability gap**.
The primitives all exist in the extension API:

- `pi.on(event, …)` — lifecycle + tool events, plus a custom `pi.events` bus
- `pi.sendUserMessage(...)` / `pi.sendMessage({…}, { triggerTurn:true, deliverAs })` —
  inject a message and **wake an idle agent**, or **queue** (`steer`/`followUp`) mid-turn
- `pi.appendEntry(customType, data)` — persist state into the session JSONL
- `session_start` / `session_shutdown` — clean lifecycle for background resources
  (`reason: "startup" | "reload" | "new" | "resume" | "fork"` / `"quit" | …`)

Reference implementation: `examples/extensions/file-trigger.ts` does the whole
core (`fs.watch` → `sendMessage({triggerTurn:true})`) in ~40 lines.

**Key reframe:** the agent is normally idle. "Non-blocking" is the *default* —
a watcher is just something that, when it fires, calls `sendMessage`/`sendUserMessage`,
which wakes the idle agent or queues cleanly during a turn. The watcher itself runs
out-of-band (a timer / spawned subprocess started at `session_start` or on a tool call),
so it never blocks the agent loop.

**Gap to close:** no packaged abstraction for "launch a non-blocking watch, see it in
a list, survive `/reload`, and hand a resume instruction back to the agent when it fires."
That is what pi-watch provides — as a single extension.

**Architecture: Option 1 — ephemeral, in-process watchers.** A watch lives only while
the pi process runs. Quit pi → watchers die, no orphan processes. Matches pi's
"no background bash, use tmux" philosophy; a persistent tmux session is the durability
story. Detached/daemon durability (Option 2/3) is explicitly deferred.

## Design

### Architecture

One extension, one in-memory registry, one background-resource pattern:

```
agent calls  watch {mode, command, interval?, timeout?, label?, resumePrompt?}
        │
        ▼
   ┌─────────────┐   register in registry      ┌──────────────────┐
   │ watch tool  │ ───────────────────────────► │ WatchRegistry    │ (Map<id,Watch>)
   └─────────────┘   pi.appendEntry("watch-armed")
        │                                              │
        │ returns IMMEDIATELY  {watchId, status}       │ starts either:
        ▼                                              │  • child_process.spawn (process)
   (turn continues — NON-BLOCKING)                     │  • setInterval (poll)
                                                        │
                          ┌────────────────────────────┘
                          ▼  on exit(process) / exit-0(poll)
                   ┌──────────────┐
                   │ fire(watch)  │  kill child / clear timer
                   └──────────────┘  status→"fired", appendEntry("watch-settled")
                          │
                          ▼  pi.sendMessage({customType:"watch-done", …}, {triggerTurn:true})
                   ┌──────────────┐
                   │ idle agent   │  → wakes, reads outcome + resumePrompt, continues the work
                   └──────────────┘   (or queues as steer/followUp if agent is mid-turn)
```

### The `watch` tool

```ts
watch({
  mode: "process" | "poll",  // required
  command: string,           // required.
                             //   process → the job itself; fires on its EXIT (any code)
                             //   poll    → a "is it done?" check; fires when it EXITS 0
  interval?: number,         // poll only, seconds (default 60)
  timeout?: number,          // optional, seconds; fires as "timed_out" if exceeded
  label?: string,            // human name; auto-derived from command if absent
  resumePrompt?: string,     // the instruction the agent acts on when the watch fires
}) → { watchId: string, label: string, status: "watching" }
```

Returns immediately. The agent's turn keeps going; the user can keep chatting.

**One tool, two modes** because the reactive shell (registry → timer/spawn → inject →
resume) is identical; only "how done is detected" differs. A `mode` field is a clearer
signal to the LLM than two tool names and halves the registry/observability code.

**Predicate strategy (deliberately dumb):** no DSL. Convention — *the poll command
exits 0 iff the watched thing reached a terminal state.* Its stdout becomes the message
body; **the agent classifies success/failure itself** from the output. Pushes conditions
into the shell (where slurm/mlflow/gh skills already live) and keeps the extension
predicate-free. Examples:

- CI: `gh pr checks 811 --watch` (settles on its own)
- Slurm: `while squeue -j 123 | grep -q 123; do sleep 60; done; sacct -j 123 --format=State`
- MLflow: a one-shot `python check_run.py <id>` exiting 0 when `status==FINISHED`

### The `watch_cancel` tool

```ts
watch_cancel({ watchId: string }) → { cancelled: true }
```
Kill subprocess / clear timer, set status `cancelled`, append `watch-settled`.

### The "done" message (the key idea)

Reuses the `file-trigger.ts` pattern. On fire, compose + inject:

```ts
const content =
  `[watch "${label}"] ${outcome} after ${duration}\n` +   // outcome: success|failed|timed_out
  `--- output (tail, last ${N} lines) ---\n${tail}\n` +
  (resumePrompt ? `\n→ Next: ${resumePrompt}` : "");

pi.sendMessage(
  { customType: "watch-done", content, display: true,
    details: { watchId, outcome, durationMs, mode } },
  { triggerTurn: true }   // wake idle agent; or queues as steer if mid-turn
);
```

`resumePrompt` is what makes "continue the work" work — the agent's note to its future
self. It is carried in the injected message, so on wake the agent knows *what* to do, not
just *that* something finished.

### Watch registry (in-memory)

```ts
type Watch = {
  id: string;
  mode: "process" | "poll";
  command: string;
  label: string;
  interval?: number;       // poll
  timeout?: number;
  resumePrompt?: string;
  startedAt: number;
  status: "watching" | "fired" | "cancelled" | "timed_out" | "errored";
  child?: ChildProcess;    // process mode
  timer?: NodeJS.Timeout;  // poll mode
  timeoutTimer?: NodeJS.Timeout;
  buffer: string[];        // ring buffer, last ~50 lines of stdout/stderr
  pollingBusy?: boolean;   // poll overlap guard (skip if previous tick still running)
};
```

### Observability

1. **Footer status** — `ctx.ui.setStatus("watch", active.length ? \`⏱ ${n} watching\` : "")`. Always-on glance.
2. **Widget above editor** — `ctx.ui.setWidget("watch", active.map(w => \`${w.label} · ${w.mode} · ${elapsed}\`))`. Updated on arm/fire/cancel and each poll tick.
3. **`/watches`** — full table: id, label, mode, command, started, elapsed, status, last poll exit.
4. **`/watches cancel <id|label>`**, **`/watches restore [id]`**.

### Lifecycle & persistence

| event | action |
|---|---|
| `watch` register | arm in registry; `pi.appendEntry("watch-armed", {…def, watchId})` |
| fire / cancel / timeout | settle in registry; `pi.appendEntry("watch-settled", {watchId, outcome, at})` |
| `session_shutdown` (any reason) | kill all timers + child processes (no orphans) |
| `session_start` `reason:"reload"` | re-arm every `watch-armed` with no matching `watch-settled` (transparent) |
| `session_start` `reason:"startup"\|"new"\|"fork"` | nothing |
| `session_start` `reason:"resume"` | do **not** auto-rearm; notify once listing pending watches, point to `/watches restore` (respects Option 1) |

Re-arm reads back via `ctx.sessionManager.getEntries()` filtered to `customType`
`watch-armed` / `watch-settled`.

### Security / trust

`command` runs with the same privilege as the bash tool — **no new trust boundary.**
Arm only in trusted projects. A poll loop spawns short-lived shells; bound `timeout`
prevents zombies. Philosophically consistent: "no background bash" constrains the *bash
tool*; an extension-managed background resource is explicitly sanctioned ("file watchers,
webhooks, CI triggers").

## Success Criteria

- Agent calls `watch` → tool returns immediately; turn continues (non-blocking). ✓
- Watched job finishes → `watch-done` message injected; agent resumes per `resumePrompt`. ✓
- Watch fires while agent is mid-turn → message queues as `steer`, no interruption. ✓
- `/watches` shows live state; cancel works. ✓
- `/reload` keeps active watches alive and tracking. ✓
- Quit pi → all timers/children cleaned up, no orphans. ✓
- Resume a session → no surprise background work; pending watches surfaced for opt-in restore. ✓

## Out of scope (deferred)

- Detached/daemon durability (Option 2/3) — use a persistent tmux session instead.
- A declarative config layer (Claude-Code-hooks-style `.json`) — the `watch` tool is enough for v1.
- Predicate DSL beyond exit-0 — the agent writes the condition into the poll command.

## Implementation sketch (~300 LOC, single file `watch.ts`)

- types + registry: ~40
- `watch` tool (spawn/poll logic, ring buffer, timeout): ~110
- fire/inject composer: ~30
- `watch_cancel` tool: ~20
- lifecycle: `session_start`/`session_shutdown` + appendEntry/restore: ~60
- `/watches` command + status + widget: ~60
