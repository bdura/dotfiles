/**
 * The deterministic state-machine driver.
 *
 * Outer loop iterates tasks in order; the inner loop walks the phase graph,
 * evaluating each transition's gate and routing back to the implementer on
 * failure (feedback as plaintext) until the terminal state is reached.
 */

import { assertCleanTree, computeDiff, extractBlock, getBaselineRef } from "./handoff.ts";
import { parsePlan } from "./plan-parser.ts";
import { WorkflowRunner } from "./runner.ts";
import type { RunContext, State, TaskSpec, WorkflowDefinition } from "./types.ts";
import { WorkflowAbort } from "./types.ts";
import type { WorkflowUI } from "./ui.ts";

export interface EngineDeps {
	cwd: string;
	agentDir: string;
	modelRuntime: import("@earendil-works/pi-coding-agent").ModelRuntime;
	ui: WorkflowUI;
	ctx: import("@earendil-works/pi-coding-agent").ExtensionCommandContext;
	signal: AbortSignal;
	planPath: string;
}

export async function runWorkflow(def: WorkflowDefinition, deps: EngineDeps): Promise<void> {
	const { cwd, ui, signal } = deps;

	await assertCleanTree(cwd, signal);
	const baselineRef = await getBaselineRef(cwd, signal);
	const tasks = parsePlan(deps.planPath);

	const stateMap = new Map<string, State>(def.states.map((s) => [s.id, s]));
	const runner = new WorkflowRunner({
		cwd,
		agentDir: deps.agentDir,
		modelRuntime: deps.modelRuntime,
		roles: def.roles,
		implementerRole: def.implementerRole,
		ui,
		signal,
		ctx: deps.ctx,
	});

	let steeringNotes = "";

	try {
		for (let taskIndex = 0; taskIndex < tasks.length; taskIndex++) {
			const task = tasks[taskIndex];
			ui.setTask(taskIndex, tasks.length, task.title);
			ui.milestone({ kind: "start", task: task.title, text: `Starting task ${taskIndex + 1}/${tasks.length}` });

			let handoffNote = "";
			const ctx: RunContext = {
				cwd,
				baselineRef,
				task,
				taskIndex,
				taskCount: tasks.length,
				steeringNotes,
				handoffNote,
				signal,
				diff: () => computeDiff(cwd, baselineRef, signal),
			};

			let state = def.initialState;
			const loopCounts = new Map<string, number>();
			let budgetUsed = 0;
			let pendingFeedback: string | undefined;

			while (true) {
				if (signal.aborted) throw new WorkflowAbort("Aborted by user.", "user");
				const st = stateMap.get(state);
				if (!st) throw new WorkflowAbort(`Unknown state '${state}'.`, "error");
				if (st.transitions.length === 0) break; // terminal
				ui.setState(st.id);

				// Run the state's agent, if any.
				if (st.role) {
					const needsDiff = st.role !== def.implementerRole;
					const diff = needsDiff ? await ctx.diff() : "";
					const result = await runner.runState(st, {
						task,
						steeringNotes,
						diff,
						handoffNote,
						feedback: pendingFeedback,
					});
					pendingFeedback = undefined;
					if (result.aborted || signal.aborted) throw new WorkflowAbort("Aborted by user.", "user");
					ctx.lastRun = result;

					if (st.role === def.implementerRole) {
						const h = extractBlock(result.output, "HANDOFF");
						if (h) {
							handoffNote = h;
							ctx.handoffNote = h;
						}
					} else if (!st.verdict) {
						const s = extractBlock(result.output, "STEERING_NOTES");
						if (s) steeringNotes = appendSteering(steeringNotes, task, s);
					}
					ui.milestone({ kind: "state", task: task.title, state: st.id, text: ui.summarizeUsage(result.usage) });
				} else {
					ctx.lastRun = undefined;
				}

				// Evaluate the (single) transition's gate.
				const tr = st.transitions[0];
				const gateResult = await tr.gate(ctx);
				budgetUsed++;
				ui.setBudget(budgetUsed, def.globalBudget);
				ui.setGate(gateResult);
				ui.milestone({
					kind: "gate",
					task: task.title,
					state: st.id,
					pass: gateResult.pass,
					text: gateResult.label ?? (gateResult.pass ? "pass" : "fail"),
				});

				// Global budget escalation.
				if (budgetUsed > def.globalBudget) {
					const decision = await ui.escalate(`global budget (${def.globalBudget}) exhausted on "${task.title}"`);
					if (decision === "abort") throw new WorkflowAbort("Aborted at budget escalation.", "budget");
					if (decision === "accept") break; // move on to next task
					budgetUsed = 0; // retry
				}

				if (gateResult.pass) {
					state = tr.onPass;
					continue;
				}

				// Failure routing with per-transition loop caps.
				const key = `${st.id}->${tr.onFail}`;
				const count = (loopCounts.get(key) ?? 0) + 1;
				loopCounts.set(key, count);
				ui.setLoop(`${st.id} ×${count}/${tr.maxLoops}`);

				if (count > tr.maxLoops) {
					const decision = await ui.escalate(`loop cap (${tr.maxLoops}) hit at "${st.id}" on "${task.title}"`);
					ui.milestone({ kind: "escalation", task: task.title, state: st.id, text: `loop cap → ${decision}` });
					if (decision === "abort") throw new WorkflowAbort(`Aborted at loop cap on '${st.id}'.`, "loop");
					if (decision === "accept") {
						state = tr.onPass;
						continue;
					}
					loopCounts.set(key, 0); // retry
				}

				pendingFeedback = gateResult.feedback;
				state = tr.onFail;
			}

			runner.endTask();
			ui.milestone({ kind: "end", task: task.title, text: `Completed task ${taskIndex + 1}/${tasks.length}` });
		}
	} finally {
		runner.disposeAll();
	}
}

function appendSteering(existing: string, task: TaskSpec, notes: string): string {
	const block = `### From ${task.title}\n${notes.trim()}`;
	return existing.trim() ? `${existing.trim()}\n\n${block}` : block;
}
