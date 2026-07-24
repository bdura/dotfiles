/**
 * Core contracts for the state-machine multi-agent workflow framework.
 *
 * The framework is deliberately domain-agnostic: it knows nothing about Python,
 * ruff, pytest, or any particular agent. A concrete workflow is expressed as a
 * `WorkflowDefinition` (see ../workflows/*.ts) plus markdown agent files.
 */

import type { Static, TSchema } from "typebox";

/** Usage accumulated across a role's sub-session. */
export interface UsageTotals {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
	turns: number;
}

export function emptyUsage(): UsageTotals {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

/** Uniform result every gate produces (decision #5). */
export interface GateResult {
	pass: boolean;
	/** Plaintext fed back to the implementer on failure. Required when pass === false. */
	feedback?: string;
	/** Optional machine-readable payload (e.g. the parsed verdict) for UI/logging. */
	structured?: unknown;
	/** Short human label for the dashboard, e.g. "ruff: 3 errors". */
	label?: string;
}

/** Result of running one role's sub-session. */
export interface RoleRunResult {
	role: string;
	/** Final assistant text output. */
	output: string;
	/** Captured structured verdict (present only for verdict states). */
	verdict?: unknown;
	usage: UsageTotals;
	aborted: boolean;
	errorMessage?: string;
}

/**
 * Per-run context handed to gates. The engine mutates `lastRun` before
 * evaluating each transition's gate so verdict gates can read the captured
 * verdict from the state's agent.
 */
export interface RunContext {
	cwd: string;
	baselineRef: string;
	task: TaskSpec;
	taskIndex: number;
	taskCount: number;
	/** Accumulated retro steering notes injected into agents (decision #11). */
	steeringNotes: string;
	/** Per-task handoff note produced by the implementer (decision #3). */
	handoffNote: string;
	signal: AbortSignal;
	/** `git diff <baselineRef>` for the current working tree. */
	diff(): Promise<string>;
	/** Set by the engine to the most recent role result before gate evaluation. */
	lastRun?: RoleRunResult;
}

/** A gate maps the current run context to a pass/fail result. */
export type Gate = (ctx: RunContext) => Promise<GateResult>;

/** An agent role, resolved from a markdown file (frontmatter + body). */
export interface AgentRole {
	name: string;
	/** provider/id or bare id; falls back to the session default when omitted. */
	model?: string;
	/** Built-in / custom tool allowlist for this role. */
	tools?: string[];
	/** System prompt (markdown body). Steering notes are prepended at runtime. */
	systemPrompt: string;
}

/** Configuration for an agent-led verdict state. */
export interface VerdictConfig<S extends TSchema = TSchema> {
	/** Typebox schema the submit_verdict tool exposes as its parameters. */
	schema: S;
	/** Description shown to the model for the submit_verdict tool. */
	toolDescription?: string;
	/** How many times to re-prompt if the agent ends without a verdict (decision #6). */
	maxReprompts: number;
	/** Map the structured verdict to a GateResult. */
	interpret: (verdict: Static<S>) => GateResult;
}

/** A phase in the machine. Terminal when `transitions` is empty. */
export interface State {
	id: string;
	/** AgentRole.name to run for this state, or "" for a pure deterministic gate state. */
	role: string;
	/** Present when this state is an agent-led verdict state. */
	verdict?: VerdictConfig;
	/** Exactly one transition for non-terminal states in v1. */
	transitions: Transition[];
}

export interface Transition {
	gate: Gate;
	onPass: string;
	onFail: string;
	/** Per-transition loop-back cap (decision #8). */
	maxLoops: number;
}

export interface TaskSpec {
	id: string;
	title: string;
	body: string;
}

export interface WorkflowDefinition {
	name: string;
	/** Resolved from markdown agent files, keyed by role name. */
	roles: Record<string, AgentRole>;
	/** The role whose sub-session persists across loop-backs (fix-forward, decision #7). */
	implementerRole: string;
	states: State[];
	initialState: string;
	/** Max total phase executions per task before human escalation (decision #8). */
	globalBudget: number;
}

/** Thrown to stop the whole run (missing verdict, user abort, budget/loop escalation). */
export class WorkflowAbort extends Error {
	constructor(
		message: string,
		readonly kind: "verdict" | "user" | "budget" | "loop" | "error" = "error",
	) {
		super(message);
		this.name = "WorkflowAbort";
	}
}
