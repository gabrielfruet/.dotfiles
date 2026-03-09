/**
 * Simple Plan Mode Extension
 *
 * KISS approach:
 * - /plan to enter plan mode
 * - /build to exit back to build mode
 * - In plan mode: read-only tools + safe bash
 * - Agent knows to just plan/analyze, no changes
 * - No todo tracking, no fancy dialogs
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { Key } from "@mariozechner/pi-tui";

const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls"];
const BUILD_MODE_TOOLS = ["read", "bash", "edit", "write", "grep", "find", "ls"];

const PLAN_CONTEXT = `[PLAN MODE]
You are in PLAN MODE - a read-only exploration and planning phase.

Guidelines:
- Use read, grep, find, ls to explore and understand the codebase
- Use bash for read-only commands (cat, grep, find, ls, git status, etc.)
- Analyze the problem and create a detailed plan
- Ask clarifying questions if needed
- DO NOT make any code changes
- Just explore and describe what you would do

When ready to execute, tell the user to run /build to switch to build mode.`;

export default function simplePlanMode(pi: ExtensionAPI): void {
	let planMode = true;

	function updateStatus(ctx: ExtensionContext): void {
		if (planMode) {
			ctx.ui.setHeader((_tui, theme) => ({
				render(_width: number): string[] {
					return [theme.fg("warning", "=== PLAN MODE === (read-only, /build to exit)")];
				},
				invalidate() {},
			}));
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("warning", "[PLAN]"));
		} else {
			ctx.ui.setHeader(undefined);
			ctx.ui.setStatus("plan-mode", ctx.ui.theme.fg("success", "[BUILD]"));
		}
	}

	function setPlanMode(ctx: ExtensionContext, enable: boolean): void {
		planMode = enable;
		
		if (planMode) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
			ctx.ui.notify("Plan mode enabled - read-only exploration", "info");
		} else {
			pi.setActiveTools(BUILD_MODE_TOOLS);
			ctx.ui.notify("Build mode enabled - full tool access", "success");
		}
		
		updateStatus(ctx);
		persistState();
	}

	function persistState(): void {
		pi.appendEntry("plan-mode-state", { enabled: planMode });
	}

	// /plan - toggle plan mode
	pi.registerCommand("plan", {
		description: "Toggle plan mode (read-only exploration)",
		handler: async (_args, ctx) => setPlanMode(ctx, !planMode),
	});

	// /build - exit plan mode, enter build mode
	pi.registerCommand("build", {
		description: "Exit plan mode, enter build mode",
		handler: async (_args, ctx) => setPlanMode(ctx, false),
	});

	// Ctrl+Alt+P to toggle
	pi.registerShortcut(Key.ctrlAlt("p"), {
		description: "Toggle plan mode",
		handler: async (ctx) => setPlanMode(ctx, !planMode),
	});

	// Block destructive bash in plan mode
	pi.on("tool_call", async (event) => {
		if (!planMode || event.toolName !== "bash") return;

		const command = (event.input.command as string).toLowerCase().trim();
		
		// Block obviously destructive commands
		const blocked = [
			"rm ", "rmdir", "mv ", "cp ", "mkdir", "touch", "chmod", "chown",
			"tee", "dd if=", "shred", ">", ">>", "git commit", "git push",
			"git add", "npm install", "npm i", "yarn add", "pnpm add",
			"pip install", "apt install", "brew install", "sudo",
		].some(blocked => command.startsWith(blocked) || command.includes(` ${blocked}`));

		if (blocked) {
			return {
				block: true,
				reason: `Plan mode: read-only. Use /build to exit plan mode first.\nBlocked: ${command}`,
			};
		}
	});

	// Inject plan context on EVERY turn (survives compaction)
	pi.on("context", async (event) => {
		if (!planMode) return;

		// Add plan mode instruction to messages so it survives compaction
		const planMessage = {
			role: "user" as const,
			content: [{ type: "text" as const, text: PLAN_CONTEXT }],
		};

		return {
			messages: [...event.messages, planMessage],
		};
	});

	// Restore state on session start
	pi.on("session_start", async (_event, ctx) => {
		// Check --plan flag (default is true, so only disable if explicitly false)
		if (pi.getFlag("plan") === false) {
			planMode = false;
		}

		// Restore from persisted session state
		const entries = ctx.sessionManager.getEntries();
		for (let i = entries.length - 1; i >= 0; i--) {
			const entry = entries[i];
			if (entry.type === "custom" && entry.customType === "plan-mode-state") {
				planMode = (entry as any).data?.enabled ?? true;
				break;
			}
		}

		if (planMode) {
			pi.setActiveTools(PLAN_MODE_TOOLS);
		}

		updateStatus(ctx);
	});
}
