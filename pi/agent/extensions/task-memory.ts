/**
 * Task Memory Extension
 *
 * Cross-session, per-directory task context. Task files are global and named
 * (~/.pi/agent/memory/<slug>.md); the *active set* is keyed by cwd, supports
 * multiple concurrent tasks, and is auto-restored when you reopen pi in a dir.
 *
 * - Auto-restore: on session_start the active set for ctx.cwd is read back.
 * - Seamless recall: on every turn each active task's file is injected as a
 *   [TASK MEMORY: <name>] message (small, curated, survives compaction).
 * - Automatic recording: the `task_memory` tool lets the agent activate/update
 *   tasks without approval (writes confined to the memory dir).
 * - Manual control: /tasks /task /untask /recall /forget.
 */

import { StringEnum } from "@mariozechner/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Type } from "typebox";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

const MEM_DIR = path.join(os.homedir(), ".pi", "agent", "memory");
const ARCHIVE_DIR = path.join(MEM_DIR, "archive");
const ACTIVE_FILE = path.join(MEM_DIR, "active.json");

function ensureDir(): void {
	fs.mkdirSync(MEM_DIR, { recursive: true });
}

function slugify(name: string): string {
	return name
		.trim()
		.toLowerCase()
		.replace(/[\s/\\]+/g, "-")
		.replace(/[^a-z0-9._-]/g, "")
		.replace(/-+/g, "-")
		.replace(/^-+|-+$/g, "");
}

function taskFile(slug: string): string {
	return path.join(MEM_DIR, `${slug}.md`);
}

function readTask(slug: string): string | undefined {
	try {
		return fs.readFileSync(taskFile(slug), "utf-8");
	} catch {
		return undefined;
	}
}

/** Display name from the "# Task: <name>" header, falling back to the slug. */
function taskName(slug: string): string {
	const match = readTask(slug)?.match(/^#\s*Task:\s*(.+)$/m);
	return match ? match[1].trim() : slug;
}

function listTaskSlugs(): string[] {
	try {
		return fs
			.readdirSync(MEM_DIR)
			.filter((f) => f.endsWith(".md"))
			.map((f) => f.slice(0, -3))
			.sort();
	} catch {
		return [];
	}
}

type ActiveMap = Record<string, string[]>;

function readActiveMap(): ActiveMap {
	try {
		const parsed = JSON.parse(fs.readFileSync(ACTIVE_FILE, "utf-8"));
		return parsed && typeof parsed === "object" ? (parsed as ActiveMap) : {};
	} catch {
		return {};
	}
}

function writeActiveMap(map: ActiveMap): void {
	ensureDir();
	fs.writeFileSync(ACTIVE_FILE, `${JSON.stringify(map, null, 2)}\n`);
}

function getActiveSlugs(cwd: string): string[] {
	return readActiveMap()[cwd] ?? [];
}

function setActiveSlugs(cwd: string, slugs: string[]): void {
	const map = readActiveMap();
	if (slugs.length) map[cwd] = slugs;
	else delete map[cwd];
	writeActiveMap(map);
}

function template(name: string): string {
	const date = new Date().toISOString().slice(0, 10);
	return `# Task: ${name}\nUpdated: ${date}\n\n## Goal\n\n\n## Status / Progress\n- \n\n## Next steps\n- \n\n## Key facts & decisions\n- \n`;
}

function scaffold(name: string, slug: string): void {
	if (!readTask(slug)) {
		ensureDir();
		fs.writeFileSync(taskFile(slug), template(name));
	}
}

const Params = Type.Object({
	action: StringEnum(["activate", "deactivate", "update", "show", "list"] as const),
	name: Type.Optional(
		Type.String({ description: "Task name. Required for activate/deactivate/update; optional for show." }),
	),
	content: Type.Optional(
		Type.String({
			description:
				"Full markdown body for update (overwrites the file). Keep it small and curated using the sections: Goal, Status / Progress, Next steps, Key facts & decisions. Never dump transcript.",
		}),
	),
});

export default function taskMemory(pi: ExtensionAPI): void {
	function updateStatus(ctx: ExtensionContext): void {
		if (!ctx.hasUI) return;
		const slugs = getActiveSlugs(ctx.cwd);
		if (slugs.length) {
			ctx.ui.setStatus("task-memory", ctx.ui.theme.fg("accent", `[TASK: ${slugs.map(taskName).join(", ")}]`));
		} else {
			ctx.ui.setStatus("task-memory", undefined);
		}
	}

	const ok = (text: string) => ({ content: [{ type: "text" as const, text }], details: {} });
	const err = (text: string) => ({ content: [{ type: "text" as const, text: `Error: ${text}` }], details: {} });

	pi.registerTool({
		name: "task_memory",
		label: "Task Memory",
		description:
			"Persist and recall the user's named tasks across sessions. Actions: " +
			"activate (create-if-missing and add the task to THIS directory's active set), " +
			"deactivate (remove from this directory's active set, keeps the file), " +
			"update (overwrite a task's curated markdown body), " +
			"show (print a task by name, or all active tasks here), " +
			"list (all known tasks). Activate a task when the user starts/names work to track; " +
			"update it after meaningful progress or on 'remember/save'. Keep files small and curated.",
		parameters: Params,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			ensureDir();
			switch (params.action) {
				case "activate": {
					if (!params.name) return err("name required for activate");
					const slug = slugify(params.name);
					if (!slug) return err("invalid name");
					scaffold(params.name, slug);
					const slugs = getActiveSlugs(ctx.cwd);
					if (!slugs.includes(slug)) slugs.push(slug);
					setActiveSlugs(ctx.cwd, slugs);
					updateStatus(ctx);
					return ok(`Activated "${params.name}" (${slug}). Active here: ${slugs.join(", ")}`);
				}
				case "deactivate": {
					if (!params.name) return err("name required for deactivate");
					const slug = slugify(params.name);
					const slugs = getActiveSlugs(ctx.cwd).filter((s) => s !== slug);
					setActiveSlugs(ctx.cwd, slugs);
					updateStatus(ctx);
					return ok(`Deactivated "${slug}". Active here: ${slugs.join(", ") || "(none)"}`);
				}
				case "update": {
					if (!params.name) return err("name required for update");
					if (params.content === undefined) return err("content required for update");
					const slug = slugify(params.name);
					if (!slug) return err("invalid name");
					const body = params.content.endsWith("\n") ? params.content : `${params.content}\n`;
					fs.writeFileSync(taskFile(slug), body);
					updateStatus(ctx);
					return ok(`Updated task "${slug}".`);
				}
				case "show": {
					if (params.name) {
						const content = readTask(slugify(params.name));
						return ok(content ?? `No task "${params.name}".`);
					}
					const slugs = getActiveSlugs(ctx.cwd);
					if (!slugs.length) return ok("No active tasks in this directory.");
					return ok(slugs.map((s) => readTask(s) ?? `(missing ${s})`).join("\n\n---\n\n"));
				}
				case "list": {
					const all = listTaskSlugs();
					if (!all.length) return ok("No tasks yet.");
					const active = new Set(getActiveSlugs(ctx.cwd));
					return ok(all.map((s) => `${active.has(s) ? "* " : "  "}${s}`).join("\n"));
				}
				default:
					return err(`unknown action: ${String((params as { action?: unknown }).action)}`);
			}
		},
	});

	// Inject each active task's memory before every LLM call (survives compaction).
	pi.on("context", async (event, ctx) => {
		const slugs = getActiveSlugs(ctx.cwd);
		if (!slugs.length) return;
		const blocks = [];
		for (const slug of slugs) {
			const content = readTask(slug);
			if (content) {
				blocks.push({
					role: "user" as const,
					content: [{ type: "text" as const, text: `[TASK MEMORY: ${taskName(slug)}]\n${content}` }],
				});
			}
		}
		if (!blocks.length) return;
		return { messages: [...event.messages, ...blocks] };
	});

	// Auto-restore this directory's active set on startup/resume/reload.
	pi.on("session_start", async (event, ctx) => {
		updateStatus(ctx);
		if (ctx.hasUI && event.reason === "resume") {
			const names = getActiveSlugs(ctx.cwd).map(taskName);
			if (names.length) ctx.ui.notify(`Resumed task memory: ${names.join(", ")}`, "info");
		}
	});

	pi.registerCommand("tasks", {
		description: "List tasks (★ = active in this directory)",
		handler: async (_args, ctx) => {
			const all = listTaskSlugs();
			if (!all.length) {
				ctx.ui.notify("No tasks yet.", "info");
				return;
			}
			const active = new Set(getActiveSlugs(ctx.cwd));
			const lines = all.map((s) => `${active.has(s) ? "★" : " "} ${taskName(s)}  (${s})`);
			ctx.ui.notify(`Tasks:\n${lines.join("\n")}`, "info");
		},
	});

	pi.registerCommand("task", {
		description: "Activate a task in this directory (creates it if new): /task <name>",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (!name) {
				ctx.ui.notify("Usage: /task <name>", "error");
				return;
			}
			const slug = slugify(name);
			scaffold(name, slug);
			const slugs = getActiveSlugs(ctx.cwd);
			if (!slugs.includes(slug)) slugs.push(slug);
			setActiveSlugs(ctx.cwd, slugs);
			updateStatus(ctx);
			ctx.ui.notify(`Active here: ${slugs.map(taskName).join(", ")}`, "info");
		},
	});

	pi.registerCommand("untask", {
		description: "Drop a task from this directory's active set (keeps the file): /untask <name>",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (!name) {
				ctx.ui.notify("Usage: /untask <name>", "error");
				return;
			}
			const slug = slugify(name);
			const slugs = getActiveSlugs(ctx.cwd).filter((s) => s !== slug);
			setActiveSlugs(ctx.cwd, slugs);
			updateStatus(ctx);
			ctx.ui.notify(`Active here: ${slugs.map(taskName).join(", ") || "(none)"}`, "info");
		},
	});

	pi.registerCommand("recall", {
		description: "Show the active task memory for this directory",
		handler: async (_args, ctx) => {
			const slugs = getActiveSlugs(ctx.cwd);
			if (!slugs.length) {
				ctx.ui.notify("No active tasks in this directory.", "info");
				return;
			}
			ctx.ui.notify(slugs.map((s) => readTask(s) ?? `(missing ${s})`).join("\n\n---\n\n"), "info");
		},
	});

	pi.registerCommand("forget", {
		description: "Archive a task and drop it from every active set: /forget <name>",
		handler: async (args, ctx) => {
			const name = args.trim();
			if (!name) {
				ctx.ui.notify("Usage: /forget <name>", "error");
				return;
			}
			const slug = slugify(name);
			const src = taskFile(slug);
			if (!fs.existsSync(src)) {
				ctx.ui.notify(`No task "${name}".`, "error");
				return;
			}
			fs.mkdirSync(ARCHIVE_DIR, { recursive: true });
			const stamp = new Date().toISOString().replace(/[:.]/g, "-");
			fs.renameSync(src, path.join(ARCHIVE_DIR, `${slug}_${stamp}.md`));
			const map = readActiveMap();
			for (const key of Object.keys(map)) {
				map[key] = map[key].filter((s) => s !== slug);
				if (!map[key].length) delete map[key];
			}
			writeActiveMap(map);
			updateStatus(ctx);
			ctx.ui.notify(`Archived "${name}".`, "info");
		},
	});
}
