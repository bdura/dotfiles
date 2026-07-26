/**
 * Role invocation via SDK in-process sub-sessions (decision #1).
 *
 * - Each non-implementer role runs in a fresh isolated AgentSession and is
 *   disposed after producing its output/verdict.
 * - The implementer role's session persists across loop-backs so feedback is
 *   delivered as a follow-up (fix-forward, decision #7).
 * - Verdict roles get read-only tools + a `submit_verdict` terminating tool
 *   whose parameters are captured in a closure (decision #6).
 */

import {
	type AgentSession,
	createAgentSession,
	DefaultResourceLoader,
	defineTool,
	type ExtensionCommandContext,
	type ModelRuntime,
	resolveCliModel,
	SessionManager,
} from "@earendil-works/pi-coding-agent";
import type { AgentRole, RoleRunResult, State, TaskSpec, VerdictConfig } from "./types";
import { emptyUsage, WorkflowAbort } from "./types";
import type { WorkflowUI } from "./ui";

export interface RunStateOptions {
	task: TaskSpec;
	steeringNotes: string;
	diff: string;
	handoffNote: string;
	/** Present when routing back to the implementer after a gate failure. */
	feedback?: string;
}

const READONLY_TOOLS = ["read", "grep", "find", "ls"];
const IMPLEMENTER_TOOLS = ["read", "write", "edit", "bash"];

export class WorkflowRunner {
	private implementerSession: AgentSession | null = null;
	private implementerStarted = false;

	constructor(
		private readonly deps: {
			cwd: string;
			agentDir: string;
			modelRuntime: ModelRuntime;
			roles: Record<string, AgentRole>;
			implementerRole: string;
			ui: WorkflowUI;
			signal: AbortSignal;
			ctx: ExtensionCommandContext;
		},
	) {}

	async runState(state: State, opts: RunStateOptions): Promise<RoleRunResult> {
		const role = this.deps.roles[state.role];
		if (!role) throw new WorkflowAbort(`No agent role '${state.role}' defined.`, "error");

		const isImplementer = state.role === this.deps.implementerRole;
		const usage = emptyUsage();
		let lastText = "";
		const captured: { value: unknown } = { value: undefined };

		const verdictConfig = state.verdict;
		const customTools = verdictConfig ? [this.makeVerdictTool(verdictConfig, captured)] : undefined;

		// Acquire a session (reuse persistent implementer session across loop-backs).
		let session: AgentSession;
		let ownSession: boolean;
		if (isImplementer && this.implementerSession) {
			session = this.implementerSession;
			ownSession = false;
		} else {
			session = await this.createRoleSession(role, opts.steeringNotes, this.roleTools(role, verdictConfig), customTools);
			if (isImplementer) {
				this.implementerSession = session;
				ownSession = false; // disposed in endTask()
			} else {
				ownSession = true;
			}
		}

		// Subscribe to session events for activity tracking and usage accumulation.
		// `unsub` (short for "unsubscribe") is the cleanup function returned by subscribe()
		// that removes this event listener. It must be called in the finally block to
		// prevent memory leaks. This follows the common JS pattern: subscribe() => cleanupFn.
		const unsub = session.subscribe((ev: any) => {
			if (ev.type === "tool_execution_start") {
				this.deps.ui.pushActivity(`${role.name}: ${formatTool(ev.toolName, ev.args)}`);
			} else if (ev.type === "message_end" && ev.message?.role === "assistant") {
				usage.turns++;
				const u = ev.message.usage;
				if (u) {
					usage.input += u.input || 0;
					usage.output += u.output || 0;
					usage.cacheRead += u.cacheRead || 0;
					usage.cacheWrite += u.cacheWrite || 0;
					usage.cost += u.cost?.total || 0;
				}
				const text = extractText(ev.message.content);
				if (text.trim()) lastText = text;
			}
		});

		try {
			if (isImplementer) {
				if (opts.feedback && this.implementerStarted) {
					await session.followUp(opts.feedback);
					await session.waitForIdle();
				} else {
					await session.prompt(buildImplementerPrompt(opts));
					this.implementerStarted = true;
				}
			} else {
				await session.prompt(buildAgentPrompt(state, opts));
				if (verdictConfig) {
					let tries = 0;
					while (captured.value === undefined && tries < verdictConfig.maxReprompts && !this.deps.signal.aborted) {
						tries++;
						this.deps.ui.pushActivity(`${role.name}: no verdict — reprompt ${tries}/${verdictConfig.maxReprompts}`);
						await session.followUp(
							"You did not submit a verdict. You MUST call the submit_verdict tool now with your structured judgement. Do not reply with prose.",
						);
						await session.waitForIdle();
					}
					if (captured.value === undefined) {
						throw new WorkflowAbort(
							`Role '${role.name}' never called submit_verdict after ${verdictConfig.maxReprompts} reprompt(s).`,
							"verdict",
						);
					}
				}
			}
		} finally {
			unsub();
			if (ownSession) session.dispose();
		}

		return {
			role: role.name,
			output: lastText,
			verdict: captured.value,
			usage,
			aborted: this.deps.signal.aborted,
		};
	}

	/** Dispose the persistent implementer session at the end of a task. */
	endTask(): void {
		if (this.implementerSession) {
			this.implementerSession.dispose();
			this.implementerSession = null;
		}
		this.implementerStarted = false;
	}

	disposeAll(): void {
		this.endTask();
	}

	private async createRoleSession(
		role: AgentRole,
		steeringNotes: string,
		tools: string[] | undefined,
		customTools: ReturnType<typeof defineTool>[] | undefined,
	): Promise<AgentSession> {
		const systemPrompt = buildSystemPrompt(role, steeringNotes);
		const loader = new DefaultResourceLoader({
			cwd: this.deps.cwd,
			agentDir: this.deps.agentDir,
			noExtensions: true, // critical: sub-sessions must not recursively load this extension (risk #5)
			noSkills: true,
			noPromptTemplates: true,
			noThemes: true,
			noContextFiles: true,
			systemPrompt,
		});
		await loader.reload();

		const model = this.resolveModel(role.model);
		const { session } = await createAgentSession({
			cwd: this.deps.cwd,
			agentDir: this.deps.agentDir,
			modelRuntime: this.deps.modelRuntime,
			model,
			tools,
			customTools,
			resourceLoader: loader,
			sessionManager: SessionManager.inMemory(this.deps.cwd),
		});

		// Propagate abort to the sub-session.
		if (this.deps.signal.aborted) void session.abort();
		else this.deps.signal.addEventListener("abort", () => void session.abort(), { once: true });

		return session;
	}

	private resolveModel(spec?: string) {
		if (!spec) return undefined;
		const r = resolveCliModel({ cliModel: spec, modelRuntime: this.deps.modelRuntime });
		if (r.error || !r.model) {
			this.deps.ui.notify(`Model '${spec}' not resolved (${r.error ?? "unknown"}); using session default.`, "warning");
			return undefined;
		}
		return r.model;
	}

	private roleTools(role: AgentRole, verdictConfig?: VerdictConfig): string[] | undefined {
		const isImplementer = role.name === this.deps.implementerRole;
		let tools = role.tools ?? (isImplementer ? IMPLEMENTER_TOOLS : READONLY_TOOLS);
		if (verdictConfig && !tools.includes("submit_verdict")) {
			tools = [...tools, "submit_verdict"];
		}
		return tools;
	}

	private makeVerdictTool(config: VerdictConfig, captured: { value: unknown }) {
		return defineTool({
			name: "submit_verdict",
			label: "Submit Verdict",
			description:
				config.toolDescription ??
				"Submit your final structured verdict. This ends your turn — call it exactly once as your last action.",
			parameters: config.schema,
			async execute(_id, params) {
				captured.value = params;
				return {
					content: [{ type: "text", text: "Verdict recorded." }],
					details: params as Record<string, unknown>,
					terminate: true,
				};
			},
		});
	}
}

// ---- prompt builders ---------------------------------------------------------

function buildSystemPrompt(role: AgentRole, steeringNotes: string): string {
	if (!steeringNotes.trim()) return role.systemPrompt;
	return `${role.systemPrompt}\n\n## Implementation notes from previous tasks (steering)\n${steeringNotes.trim()}`;
}

function buildImplementerPrompt(opts: RunStateOptions): string {
	return [
		"Implement the following task. Keep changes tightly scoped to this task only.",
		"",
		"## Task",
		opts.task.body,
		"",
		"When finished, end your reply with a section exactly like:",
		"### HANDOFF",
		"- Files changed: ...",
		"- Key decisions: ...",
		"- Assumptions / follow-ups: ...",
	].join("\n");
}

function buildAgentPrompt(state: State, opts: RunStateOptions): string {
	const diffBlock = ["## Diff since baseline", "```diff", opts.diff, "```"].join("\n");
	if (state.verdict) {
		return [
			"Judge the change described below against your role's criteria.",
			"",
			"## Task goal",
			opts.task.body,
			"",
			"## Implementer handoff note",
			opts.handoffNote || "(none provided)",
			"",
			diffBlock,
			"",
			"Do NOT modify any files. End by calling the submit_verdict tool exactly once with your structured judgement.",
		].join("\n");
	}
	// Retro-style role: update docs and emit steering notes.
	return [
		"The task below has passed validation and review. Update documentation as needed and capture steering notes.",
		"",
		"## Task goal",
		opts.task.body,
		"",
		diffBlock,
		"",
		"Update any relevant docs (README, module docs) to reflect these changes.",
		"Then end your reply with a section exactly like:",
		"### STEERING_NOTES",
		"Concise bullets of gotchas / conventions / context useful for the REMAINING tasks. Omit the section if nothing is notable.",
	].join("\n");
}

// ---- helpers -----------------------------------------------------------------

function extractText(content: unknown): string {
	if (!Array.isArray(content)) return "";
	return content
		.filter((p: any) => p?.type === "text" && typeof p.text === "string")
		.map((p: any) => p.text)
		.join("");
}

function truncate(s: unknown, n = 60): string {
	const str = String(s ?? "");
	return str.length > n ? `${str.slice(0, n)}…` : str;
}

function formatTool(name: string, args: any): string {
	switch (name) {
		case "bash":
			return `$ ${truncate(args?.command)}`;
		case "read":
			return `read ${truncate(args?.path, 48)}`;
		case "edit":
			return `edit ${truncate(args?.path, 48)}`;
		case "write":
			return `write ${truncate(args?.path, 48)}`;
		case "grep":
			return `grep ${truncate(args?.pattern, 32)}`;
		case "submit_verdict":
			return "submit_verdict";
		default:
			return name;
	}
}
