/**
 * pi-watch — Non-blocking job watchers
 *
 * Lets the agent launch watchers that react when an async job finishes, WITHOUT
 * blocking the agent turn. The watcher runs out-of-band (spawned subprocess or
 * a poll timer); when it fires, a `watch-done` message is injected with
 * `triggerTurn:true`, which wakes an idle agent or queues cleanly mid-turn.
 *
 * Two modes, one tool:
 *   process — spawn `command`; fire on its EXIT (any code)
 *   poll    — run `command` every `interval`s; fire when it EXITS 0
 *
 * The poll command's stdout becomes the done-message body; the agent classifies
 * success/failure itself. `resumePrompt` is the agent's note-to-self for what to
 * do on wake.
 *
 * Lifecycle: watchers live only while the pi process runs (Option 1). Quit pi
 * -> all timers/children are killed. `/reload` re-arms transparently; resuming
 * a session surfaces pending watches for opt-in `/watches restore`.
 *
 * Place at ~/.pi/agent/extensions/watch.ts (auto-discovered, /reload-able).
 */

import { spawn, type ChildProcess } from "node:child_process";
import type { ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, Text, truncateToWidth } from "@earendil-works/pi-tui";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";

// ---------------------------------------------------------------- types

type Mode = "process" | "poll";
type Status = "watching" | "fired" | "cancelled" | "timed_out" | "errored";
type Outcome = Exclude<Status, "watching"> | "success" | "failed";

interface WatchDef {
	mode: Mode;
	command: string;
	interval?: number;
	timeout?: number;
	label?: string;
	resumePrompt?: string;
}

interface Watch extends WatchDef {
	id: string;
	startedAt: number;
	status: Status;
	child?: ChildProcess;
	timer?: NodeJS.Timeout;
	timeoutTimer?: NodeJS.Timeout;
	buffer: string[]; // ring buffer, last N lines (process stdout/stderr or poll output)
	lastOutput?: string; // most recent poll stdout (poll mode)
	pollingBusy?: boolean;
}

const BUFFER_LINES = 50;
const STATUS_KEY = "watch";

// ---------------------------------------------------------------- helpers

let counter = 0;
const genId = (): string => `w${++counter}`;

function deriveLabel(command: string): string {
	const c = command.trim().replace(/\s+/g, " ");
	return c.length > 40 ? c.slice(0, 37) + "…" : c;
}

function formatDuration(ms: number): string {
	if (ms < 0) ms = 0;
	const s = Math.floor(ms / 1000);
	const h = Math.floor(s / 3600);
	const m = Math.floor((s % 3600) / 60);
	const sec = s % 60;
	if (h > 0) return `${h}h${String(m).padStart(2, "0")}m`;
	if (m > 0) return `${m}m${String(sec).padStart(2, "0")}s`;
	return `${sec}s`;
}

function pushLine(buf: string[], line: string): void {
	buf.push(line);
	if (buf.length > BUFFER_LINES) buf.splice(0, buf.length - BUFFER_LINES);
}

/** Run a short command to completion, returning exit code + combined output. */
function runShort(command: string, cwd: string): Promise<{ code: number | null; stdout: string }> {
	return new Promise((resolve) => {
		let out = "";
		let settled = false;
		const done = (code: number | null) => {
			if (settled) return;
			settled = true;
			resolve({ code, stdout: out });
		};
		try {
			const child = spawn(command, { shell: true, cwd });
			child.stdout?.on("data", (d) => (out += d.toString()));
			child.stderr?.on("data", (d) => (out += d.toString()));
			child.on("error", (err) => {
				out += `\n[spawn error: ${err.message}]`;
				done(1);
			});
			child.on("close", (code) => done(code));
		} catch (e) {
			out += `\n[spawn threw: ${e instanceof Error ? e.message : String(e)}]`;
			done(1);
		}
	});
}

// ---------------------------------------------------------------- extension

export default function watchExtension(pi: ExtensionAPI) {
	const registry = new Map<string, Watch>();
	let currentCtx: ExtensionContext | undefined;
	let dead = false; // session_shutdown fired; suppress further side effects
	let uiTimer: NodeJS.Timeout | undefined;

	// ----------------------------------------------------------- UI refresh

	function refreshUI(): void {
		const ctx = currentCtx;
		if (!ctx || !ctx.hasUI) return;
		const active = [...registry.values()].filter((w) => w.status === "watching");
		if (active.length === 0) {
			ctx.ui.setStatus(STATUS_KEY, undefined);
			ctx.ui.setWidget(STATUS_KEY, []);
			if (uiTimer) {
				clearInterval(uiTimer);
				uiTimer = undefined;
			}
			return;
		}
		ctx.ui.setStatus(STATUS_KEY, `⏱ ${active.length} watching`);
		ctx.ui.setWidget(
			STATUS_KEY,
			active.map((w) => `${w.label} · ${w.mode} · ${formatDuration(Date.now() - w.startedAt)}`),
		);
		// Keep elapsed time ticking while watches are active (5s cadence).
		if (!uiTimer) {
			uiTimer = setInterval(() => {
				if (dead) return;
				const stillActive = [...registry.values()].some((w) => w.status === "watching");
				if (stillActive) refreshUI();
			}, 5000);
		}
	}

	// ----------------------------------------------------------- fire / cancel

	function settle(w: Watch, outcome: Outcome, payload?: string): void {
		if (w.status !== "watching") return; // idempotent
		w.status =
			outcome === "success" || outcome === "failed"
				? "fired"
				: (outcome as Status);
		// tear down background resources
		if (w.child) {
			try {
				w.child.kill("SIGTERM");
			} catch {
				/* ignore */
			}
			w.child = undefined;
		}
		if (w.timer) {
			clearInterval(w.timer);
			w.timer = undefined;
		}
		if (w.timeoutTimer) {
			clearTimeout(w.timeoutTimer);
			w.timeoutTimer = undefined;
		}

		const durationMs = Date.now() - w.startedAt;
		pi.appendEntry("watch-settled", { watchId: w.id, outcome, at: Date.now() });
		refreshUI();

		if (dead) return; // shutting down: don't inject after teardown

		// Compose and inject the wake-up message (reuses file-trigger.ts pattern).
		const tail = (payload ?? w.lastOutput ?? w.buffer.join("\n")).trim();
		const tailBlock = tail
			? `\n--- output (tail, last ${BUFFER_LINES} lines) ---\n${tail.split("\n").slice(-BUFFER_LINES).join("\n")}`
			: "";
		const next = w.resumePrompt ? `\n\n→ Next: ${w.resumePrompt}` : "";
		const content = `[watch "${w.label}"] ${outcome} after ${formatDuration(durationMs)}${tailBlock}${next}`;

		pi.sendMessage(
			{
				customType: "watch-done",
				content,
				display: true,
				details: { watchId: w.id, outcome, durationMs, mode: w.mode },
			},
			{ triggerTurn: true }, // wake idle agent; queues as steer if mid-turn
		);
	}

	// ----------------------------------------------------------- arm

	function arm(def: WatchDef): Watch {
		const w: Watch = {
			...def,
			id: genId(),
			startedAt: Date.now(),
			status: "watching",
			buffer: [],
		};
		registry.set(w.id, w);
		pi.appendEntry("watch-armed", {
			watchId: w.id,
			mode: w.mode,
			command: w.command,
			interval: w.interval,
			timeout: w.timeout,
			label: w.label,
			resumePrompt: w.resumePrompt,
			startedAt: w.startedAt,
		});

		const cwd = currentCtx?.cwd ?? process.cwd();

		if (w.mode === "process") {
			const child = spawn(w.command, { shell: true, cwd });
			w.child = child;
			child.stdout?.on("data", (d) =>
				d.toString().split("\n").forEach((l) => pushLine(w.buffer, l)),
			);
			child.stderr?.on("data", (d) =>
				d.toString().split("\n").forEach((l) => pushLine(w.buffer, l)),
			);
			child.on("error", (err) => {
				pushLine(w.buffer, `[spawn error: ${err.message}]`);
				settle(w, "errored");
			});
			child.on("close", (code) => settle(w, code === 0 ? "success" : "failed"));
		} else {
			// poll mode: exit-0 means terminal state reached.
			const intervalMs = Math.max(1, (w.interval ?? 60)) * 1000;
			const tick = async () => {
				if (dead || w.status !== "watching" || w.pollingBusy) return;
				w.pollingBusy = true;
				try {
					const { code, stdout } = await runShort(w.command, cwd);
					if (dead || w.status !== "watching") return;
					w.lastOutput = stdout;
					if (stdout.trim()) pushLine(w.buffer, stdout.trim());
					refreshUI();
					if (code === 0) settle(w, "success", stdout);
				} catch (e) {
					pushLine(w.buffer, `[poll error: ${e instanceof Error ? e.message : String(e)}]`);
				} finally {
					w.pollingBusy = false;
				}
			};
			w.timer = setInterval(tick, intervalMs);
			void tick(); // immediate first check
		}

		if (w.timeout && w.timeout > 0) {
			w.timeoutTimer = setTimeout(() => settle(w, "timed_out"), w.timeout * 1000);
		}

		refreshUI();
		return w;
	}

	function cancel(w: Watch): void {
		settle(w, "cancelled");
	}

	function findByRef(ref: string): Watch | undefined {
		return registry.get(ref) ?? [...registry.values()].find((w) => w.label === ref);
	}

	// ----------------------------------------------------------- tools

	const watchParams = Type.Object({
		mode: StringEnum(["process", "poll"] as const, {
			description:
				"process = spawn `command` and fire on its exit (any code). poll = run `command` every `interval`s and fire when it exits 0 (terminal state reached).",
		}),
		command: Type.String({
			description:
				"process: the job to run. poll: a check command that exits 0 iff the watched thing is done (its stdout becomes the wake-up message body).",
		}),
		interval: Type.Optional(
			Type.Number({ description: "poll only: seconds between checks (default 60).", minimum: 1 }),
		),
		timeout: Type.Optional(
			Type.Number({ description: "optional: seconds; fires as timed_out if exceeded.", minimum: 1 }),
		),
		label: Type.Optional(Type.String({ description: "human name; auto-derived from command if omitted." })),
		resumePrompt: Type.Optional(
			Type.String({
				description: "What to do when the watch fires. Carried in the wake-up message so the agent knows how to continue.",
			}),
		),
	});

	pi.registerTool({
		name: "watch",
		label: "Watch",
		description:
			"Launch a NON-BLOCKING background watcher that fires (and resumes the agent) when an async job finishes — e.g. wait for CI, a training run, or long-running code. Returns immediately with a watchId; the agent turn continues. Use mode 'process' to run a job yourself, or 'poll' to wait on external state (CI/slurm/mlflow) via a check command that exits 0 when done.",
		promptSnippet: "Launch a non-blocking watcher that resumes the agent when a job/CI/training run finishes",
		promptGuidelines: [
			"Use watch to wait on long async work without blocking — it returns immediately and resumes the conversation when the job finishes.",
			"Prefer poll mode with a check command that exits 0 on terminal state for CI/slurm/mlflow; the command's stdout is handed back as context.",
			"Always pass resumePrompt describing what to do when the watch fires, so the continuation is unambiguous.",
		],
		parameters: watchParams,

		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			// Keep currentCtx fresh (tool ctx is the most reliable source).
			currentCtx = ctx;
			const def: WatchDef = {
				mode: params.mode,
				command: params.command.trim(),
				interval: params.interval,
				timeout: params.timeout,
				label: (params.label?.trim() || deriveLabel(params.command)),
				resumePrompt: params.resumePrompt?.trim() || undefined,
			};
			if (!def.command) {
				return {
					content: [{ type: "text", text: "Error: command is required" }],
					details: { error: "command required" },
				};
			}
			const w = arm(def);
			const summary =
				params.mode === "poll"
					? `polling every ${def.interval ?? 60}s`
					: "process running";
			return {
				content: [
					{
						type: "text",
						text: `Watching "${w.label}" (${summary}). watchId=${w.id}\nI'll continue now and react when it finishes — no need to wait.`,
					},
				],
				details: { watchId: w.id, status: "watching", mode: w.mode, label: w.label },
			};
		},

		renderCall(args, theme) {
			const head = theme.fg("toolTitle", theme.bold("watch "));
			const mode = theme.fg("accent", args.mode);
			const cmd = theme.fg("dim", `"${args.command}"`);
			return new Text(`${head}${mode} ${cmd}`, 0, 0);
		},

		renderResult(result, _opts, theme) {
			const text = result.content[0];
			return new Text(theme.fg("success", "⏱ ") + (text?.type === "text" ? text.text : ""), 0, 0);
		},
	});

	const cancelParams = Type.Object({
		watchId: Type.String({ description: "watch id (e.g. w1) or label" }),
	});

	pi.registerTool({
		name: "watch_cancel",
		label: "Cancel Watch",
		description: "Cancel an active watcher by id or label.",
		parameters: cancelParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			currentCtx = ctx;
			const w = findByRef(params.watchId);
			if (!w) {
				return { content: [{ type: "text", text: `No watch matching "${params.watchId}"` }] };
			}
			if (w.status !== "watching") {
				return { content: [{ type: "text", text: `Watch ${w.id} already ${w.status}` }] };
			}
			cancel(w);
			return { content: [{ type: "text", text: `Cancelled watch ${w.id} ("${w.label}")` }] };
		},
		renderCall(args, theme) {
			return new Text(theme.fg("toolTitle", theme.bold("watch_cancel ")) + theme.fg("dim", args.watchId), 0, 0);
		},
	});

	// ----------------------------------------------------------- /watches command

	pi.registerCommand("watches", {
		description: "List watchers, or: /watches cancel <id|label> | /watches restore <id>",
		handler: async (args, ctx) => {
			currentCtx = ctx;
			const trimmed = args.trim();
			const parts = trimmed.split(/\s+/);
			const sub = parts[0]?.toLowerCase();

			if (sub === "cancel") {
				const ref = parts.slice(1).join(" ");
				if (!ref) {
					ctx.ui.notify("Usage: /watches cancel <id|label>", "warning");
					return;
				}
				const w = findByRef(ref);
				if (!w) {
					ctx.ui.notify(`No watch matching "${ref}"`, "warning");
					return;
				}
				if (w.status !== "watching") {
					ctx.ui.notify(`Watch ${w.id} already ${w.status}`, "info");
					return;
				}
				cancel(w);
				ctx.ui.notify(`Cancelled ${w.id} ("${w.label}")`, "info");
				return;
			}

			if (sub === "restore") {
				const id = parts[1];
				if (!id) {
					ctx.ui.notify("Usage: /watches restore <id>", "warning");
					return;
				}
				const def = pendingFromEntries(ctx).find((p) => p.id === id || `w${p.id}` === id);
				if (!def) {
					ctx.ui.notify(`No restorable watch "${id}"`, "warning");
					return;
				}
				arm(defEntryToDef(def));
				ctx.ui.notify(`Restored ${def.id}`, "info");
				return;
			}

			// default: show list
			if (ctx.mode !== "tui") {
				ctx.ui.notify(renderListText(), "info");
				return;
			}
			await ctx.ui.custom<void>((_tui, theme, _kb, done) => {
				return new WatchesListComponent([...registry.values()], theme, () => done());
			});
		},
	});

	function renderListText(): string {
		const all = [...registry.values()];
		if (all.length === 0) return "No watches.";
		return all
			.map(
				(w) =>
					`${w.id}  [${w.status}]  ${w.mode}  "${w.label}"  ${formatDuration(Date.now() - w.startedAt)}`,
			)
			.join("\n");
	}

	// ----------------------------------------------------------- restore entries

	interface ArmedEntry {
		id: string;
		mode: Mode;
		command: string;
		interval?: number;
		timeout?: number;
		label?: string;
		resumePrompt?: string;
	}

	/** Reads watch-armed entries with no matching watch-settled on the current branch. */
	function pendingFromEntries(ctx: ExtensionContext): ArmedEntry[] {
		const armed = new Map<string, ArmedEntry>();
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "custom") continue;
			if (entry.customType === "watch-armed" && entry.data) {
				const d = entry.data as Record<string, unknown>;
				armed.set(String(d.watchId), {
					id: String(d.watchId),
					mode: d.mode as Mode,
					command: String(d.command),
					interval: d.interval as number | undefined,
					timeout: d.timeout as number | undefined,
					label: d.label as string | undefined,
					resumePrompt: d.resumePrompt as string | undefined,
				});
			} else if (entry.customType === "watch-settled" && entry.data) {
				armed.delete(String((entry.data as Record<string, unknown>).watchId));
			}
		}
		return [...armed.values()];
	}

	function defEntryToDef(e: ArmedEntry): WatchDef {
		return {
			mode: e.mode,
			command: e.command,
			interval: e.interval,
			timeout: e.timeout,
			label: e.label ?? deriveLabel(e.command),
			resumePrompt: e.resumePrompt,
		};
	}

	// ----------------------------------------------------------- lifecycle

	pi.on("session_start", async (event, ctx) => {
		currentCtx = ctx;
		dead = false;

		if (event.reason === "reload") {
			// Transparent continuity: re-arm watches still active at reload time.
			// (process-mode watches re-spawn their command.)
			const pending = pendingFromEntries(ctx);
			for (const e of pending) arm(defEntryToDef(e));
			if (pending.length && ctx.hasUI) {
				ctx.ui.notify(`Re-armed ${pending.length} watch(es) after reload`, "info");
			}
			return;
		}

		if (event.reason === "resume") {
			// Fresh process (Option 1): do NOT auto-rearm. Surface pending for opt-in restore.
			const pending = pendingFromEntries(ctx);
			if (pending.length && ctx.hasUI) {
				const list = pending
					.map((e) => `  • ${e.id} (${e.mode}): ${e.label ?? e.command}`)
					.join("\n");
				ctx.ui.notify(
					`${pending.length} watch(es) were active when this session closed:\n${list}\nRe-arm with /watches restore <id>`,
					"info",
				);
			}
			return;
		}
		// startup / new / fork: registry is empty, nothing to do.
	});

	pi.on("session_shutdown", async () => {
		dead = true;
		for (const w of registry.values()) {
			if (w.status !== "watching") continue;
			// Kill background resources WITHOUT injecting a wake-up message.
			w.status = "cancelled";
			try {
				w.child?.kill("SIGTERM");
			} catch {
				/* ignore */
			}
			if (w.timer) clearInterval(w.timer);
			if (w.timeoutTimer) clearTimeout(w.timeoutTimer);
		}
		if (uiTimer) {
			clearInterval(uiTimer);
			uiTimer = undefined;
		}
		registry.clear();
	});
}

// ---------------------------------------------------------------- /watches list UI

class WatchesListComponent {
	private watches: Watch[];
	private theme: Theme;
	private onClose: () => void;

	constructor(watches: Watch[], theme: Theme, onClose: () => void) {
		this.watches = watches;
		this.theme = theme;
		this.onClose = onClose;
	}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
			this.onClose();
		}
	}

	render(width: number): string[] {
		const th = this.theme;
		const lines: string[] = [];
		lines.push("");
		const title = th.fg("accent", " Watches ");
		lines.push(
			truncateToWidth(
				th.fg("borderMuted", "─".repeat(3)) + title + th.fg("borderMuted", "─".repeat(Math.max(0, width - 12))),
				width,
			),
		);
		lines.push("");

		if (this.watches.length === 0) {
			lines.push(truncateToWidth(`  ${th.fg("dim", "No watches. Use the watch tool to launch one.")}`, width));
		} else {
			const sorted = [...this.watches].sort((a, b) => b.startedAt - a.startedAt);
			for (const w of sorted) {
				const icon =
					w.status === "watching"
						? th.fg("accent", "⏱")
						: w.status === "fired"
							? th.fg("success", "✓")
							: th.fg("dim", "○");
				const id = th.fg("accent", w.id.padEnd(3));
				const mode = th.fg("muted", w.mode.padEnd(7));
				const elapsed = th.fg("dim", formatDuration(Date.now() - w.startedAt).padStart(7));
				const label = th.fg(w.status === "watching" ? "text" : "dim", w.label);
				lines.push(truncateToWidth(`  ${icon} ${id} ${mode} ${elapsed}  ${label}`, width));
			}
		}

		lines.push("");
		lines.push(truncateToWidth(`  ${th.fg("dim", "Escape to close · /watches cancel <id>")}`, width));
		lines.push("");
		return lines;
	}
}
