/**
 * Task: Main abstraction for single-task workflow execution.
 *
 * Encapsulates the state machine loop for a single task, managing:
 * - Current state and transitions
 * - Loop counts per transition
 * - Global budget tracking
 * - Pending feedback for loop-backs
 * - Lazy diff computation with caching
 * - Handoff note accumulation
 *
 * Uses WorkflowRunner internally for agent execution.
 */

import { computeDiff, extractBlock } from "./handoff";
import { WorkflowRunner } from "./runner";
import { WorkflowAbort } from "./types";
import type { GateResult, RunContext, State, TaskSpec, UsageTotals, WorkflowDefinition } from "./types";
import type { WorkflowUI } from "./ui";
import type { ModelRuntime, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

/** Result of running a complete task workflow. */
export interface TaskResult {
	success: boolean;
	finalState: string;
	error?: WorkflowAbort;
	usage: UsageTotals;
	handoffNote: string;
	steeringNotes: string;
}

function emptyUsage(): UsageTotals {
	return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, turns: 0 };
}

function accumulateUsage(a: UsageTotals, b: UsageTotals): UsageTotals {
	return {
		input: a.input + b.input,
		output: a.output + b.output,
		cacheRead: a.cacheRead + b.cacheRead,
		cacheWrite: a.cacheWrite + b.cacheWrite,
		cost: a.cost + b.cost,
		turns: a.turns + b.turns,
	};
}

/**
 * Dependencies required to run a Task.
 */
export interface TaskDeps {
	cwd: string;
	baselineRef: string;
	steeringNotes: string;
	modelRuntime: ModelRuntime;
	ui: WorkflowUI;
	signal: AbortSignal;
	agentDir: string;
	ctx: ExtensionCommandContext;
}

export class Task {
	private loopCounts = new Map<string, number>();
	private budgetUsed = 0;
	private pendingFeedback?: string;
	private currentState: string;
	private cachedDiff?: string;
	private handoffNote = "";
	private totalUsage: UsageTotals = emptyUsage();
	private readonly runner: WorkflowRunner;

	constructor(
		private readonly spec: TaskSpec,
		private readonly def: WorkflowDefinition,
		private readonly deps: TaskDeps,
	) {
		this.currentState = def.initialState;
		this.runner = new WorkflowRunner({
			cwd: deps.cwd,
			agentDir: deps.agentDir,
			modelRuntime: deps.modelRuntime,
			roles: def.roles,
			implementerRole: def.implementerRole,
			ui: deps.ui,
			signal: deps.signal,
			ctx: deps.ctx,
		});
	}

	/**
	 * Run the complete workflow for this task.
	 * Returns a TaskResult with success/failure info - never throws.
	 */
	async run(): Promise<TaskResult> {
		const stateMap = new Map<string, State>(this.def.states.map((s) => [s.id, s]));
		let finalState = this.currentState;
		let gateResult: GateResult | undefined;
		let error: WorkflowAbort | undefined;

		try {
			this.deps.ui.setTask(this.spec.title);
			this.deps.ui.milestone({ kind: "start", task: this.spec.title, text: `Starting task: ${this.spec.title}` });

			while (true) {
				if (this.deps.signal.aborted) {
					throw new WorkflowAbort("Aborted by user.", "user");
				}

				const state = stateMap.get(this.currentState);
				if (!state) {
					throw new WorkflowAbort(`Unknown state '${this.currentState}'.`, "error");
				}
				if (state.transitions.length === 0) {
					// Terminal state
					finalState = this.currentState;
					break;
				}

				this.deps.ui.setState(state.id);

				// Run the state's agent, if any
				let result: { output: string; usage: UsageTotals; verdict?: unknown; aborted: boolean } | undefined;
				if (state.role) {
					const needsDiff = state.role !== this.def.implementerRole;
					const diff = needsDiff ? await this.getDiff() : "";
					const runResult = await this.runner.runState(state, {
						task: this.spec,
						steeringNotes: this.deps.steeringNotes,
						diff,
						handoffNote: this.handoffNote,
						feedback: this.pendingFeedback,
					});
					result = {
						output: runResult.output,
						usage: runResult.usage,
						verdict: runResult.verdict,
						aborted: runResult.aborted,
					};
					this.totalUsage = accumulateUsage(this.totalUsage, runResult.usage);
					this.pendingFeedback = undefined;

					// Extract handoff note from implementer
					if (state.role === this.def.implementerRole) {
						const h = extractBlock(runResult.output, "HANDOFF");
						if (h) {
							this.handoffNote = h;
						}
					}
					// Extract steering notes from non-verdict roles
					else if (!state.verdict) {
						const s = extractBlock(runResult.output, "STEERING_NOTES");
						if (s) {
							this.deps.steeringNotes = this.appendSteering(this.deps.steeringNotes, s);
						}
					}

					this.deps.ui.milestone({
						kind: "state",
						task: this.spec.title,
						state: state.id,
						text: this.deps.ui.summarizeUsage(runResult.usage),
					});

					if (runResult.aborted || this.deps.signal.aborted) {
						throw new WorkflowAbort("Aborted by user.", "user");
					}
				}

				// Build RunContext for gate evaluation
				const runCtx = this.buildRunContext(result);

				// Evaluate the (single) transition's gate
				const tr = state.transitions[0];
				gateResult = await tr.gate(runCtx);
				this.budgetUsed++;
				this.deps.ui.setBudget(this.budgetUsed, this.def.globalBudget);
				this.deps.ui.setGate(gateResult);
				this.deps.ui.milestone({
					kind: "gate",
					task: this.spec.title,
					state: state.id,
					pass: gateResult.pass,
					text: gateResult.label ?? (gateResult.pass ? "pass" : "fail"),
				});

				// Global budget escalation
				if (this.budgetUsed > this.def.globalBudget) {
					const decision = await this.deps.ui.escalate(`global budget (${this.def.globalBudget}) exhausted on "${this.spec.title}"`);
					this.deps.ui.milestone({ kind: "escalation", task: this.spec.title, state: state.id, text: `global budget → ${decision}` });
					if (decision === "abort") {
						throw new WorkflowAbort("Aborted at budget escalation.", "budget");
					}
					if (decision === "accept") {
						this.currentState = tr.onPass;
						continue;
					}
					this.budgetUsed = 0; // retry
				}

				if (gateResult.pass) {
					this.currentState = tr.onPass;
					continue;
				}

				// Failure routing with per-transition loop caps
				const key = `${state.id}->${tr.onFail}`;
				const count = (this.loopCounts.get(key) ?? 0) + 1;
				this.loopCounts.set(key, count);
				this.deps.ui.setLoop(`${state.id} ×${count}/${tr.maxLoops}`);

				if (count > tr.maxLoops) {
					const decision = await this.deps.ui.escalate(`loop cap (${tr.maxLoops}) hit at "${state.id}" on "${this.spec.title}"`);
					this.deps.ui.milestone({ kind: "escalation", task: this.spec.title, state: state.id, text: `loop cap → ${decision}` });
					if (decision === "abort") {
						throw new WorkflowAbort(`Aborted at loop cap on '${state.id}'.`, "loop");
					}
					if (decision === "accept") {
						this.currentState = tr.onPass;
						continue;
					}
					this.loopCounts.set(key, 0); // retry
				}

				this.pendingFeedback = gateResult.feedback;
				this.currentState = tr.onFail;
			}

			finalState = this.currentState;
			this.deps.ui.milestone({ kind: "end", task: this.spec.title, text: `Completed task: ${this.spec.title}` });

			return {
				success: true,
				finalState,
				usage: this.totalUsage,
				handoffNote: this.handoffNote,
				steeringNotes: this.deps.steeringNotes,
			};
		} catch (err) {
			if (err instanceof WorkflowAbort) {
				error = err;
				finalState = this.currentState;
				this.deps.ui.milestone({ kind: "end", task: this.spec.title, text: `Task failed: ${err.message}` });
				return {
					success: false,
					finalState,
					error: err,
					usage: this.totalUsage,
					handoffNote: this.handoffNote,
					steeringNotes: this.deps.steeringNotes,
				};
			}
			throw err;
		} finally {
			this.runner.endTask();
			this.runner.disposeAll();
		}
	}

	/**
	 * Lazily compute and cache the git diff for this task.
	 */
	private async getDiff(): Promise<string> {
		if (!this.cachedDiff) {
			this.cachedDiff = await computeDiff(this.deps.cwd, this.deps.baselineRef, this.deps.signal);
		}
		return this.cachedDiff;
	}

	/**
	 * Build a RunContext for gate evaluation.
	 */
	private buildRunContext(result?: { output: string; usage: UsageTotals; verdict?: unknown; aborted: boolean }): RunContext {
		const ctx: RunContext = {
			cwd: this.deps.cwd,
			baselineRef: this.deps.baselineRef,
			task: this.spec,
			taskIndex: 0,
			taskCount: 1,
			steeringNotes: this.deps.steeringNotes,
			handoffNote: this.handoffNote,
			signal: this.deps.signal,
			diff: () => this.getDiff(),
		};
		if (result) {
			ctx.lastRun = {
				role: this.def.states.find((s) => s.id === this.currentState)?.role ?? "",
				output: result.output,
				verdict: result.verdict,
				usage: result.usage,
				aborted: result.aborted,
			};
		}
		return ctx;
	}

	/**
	 * Append steering notes from a task.
	 */
	private appendSteering(existing: string, notes: string): string {
		const block = `### From ${this.spec.title}\n${notes.trim()}`;
		return existing.trim() ? `${existing.trim()}\n\n${block}` : block;
	}
}
