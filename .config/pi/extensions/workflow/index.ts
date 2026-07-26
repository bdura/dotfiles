/**
 * State-machine multi-agent workflow extension.
 *
 * Usage: /workflow <path-to-plan.md>
 *
 * Drives a deterministic implement -> gate -> validate -> review -> retro pipeline
 * per task, using isolated SDK sub-sessions for each agent role. See plan.md for
 * the full design and rationale.
 */

import { dirname, isAbsolute, join } from "node:path";
import {
	type ExtensionAPI,
	getAgentDir,
	ModelRuntime,
} from "@earendil-works/pi-coding-agent";
import { assertRolesPresent, discoverRoles } from "./framework/agents";
import { assertCleanTree, getBaselineRef } from "./framework/handoff";
import { parsePlan } from "./framework/plan-parser";
import { Task, type TaskResult } from "./framework/task";
import { WorkflowUI } from "./framework/ui";
import { WorkflowAbort } from "./framework/types";
import { buildPythonWorkflow } from "./workflows/python";

// Resolve this extension's directory so we can find agents/ regardless of cwd.
const EXT_DIR = dirname(new URL(import.meta.url).pathname);
const AGENTS_DIR = join(EXT_DIR, "agents");

export default function (pi: ExtensionAPI) {
	let modelRuntime: ModelRuntime | undefined;
	// Active run controller, so shutdown can abort a running workflow.
	let activeController: AbortController | undefined;

	pi.on("session_shutdown", async () => {
		activeController?.abort();
	});

	pi.registerCommand("workflow", {
		description: "Run the deterministic multi-agent workflow: /workflow <plan-path>",
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("The workflow command requires interactive UI.", "error");
				return;
			}
			const planPath = resolvePlanPath(args.trim(), ctx.cwd);
			if (!planPath) {
				ctx.ui.notify("Usage: /workflow <path-to-plan.md>", "warning");
				return;
			}

			const controller = new AbortController();
			activeController = controller;
			const ui = new WorkflowUI(pi, ctx);

			try {
				if (!modelRuntime) modelRuntime = await ModelRuntime.create();

				const roles = discoverRoles(AGENTS_DIR);
				const def = buildPythonWorkflow(roles);
				assertRolesPresent(roles, [def.implementerRole, ...def.states.map((s) => s.role).filter(Boolean)]);

				await assertCleanTree(ctx.cwd, controller.signal);
				const baselineRef = await getBaselineRef(ctx.cwd, controller.signal);
				const tasks = parsePlan(planPath);
				
				if (tasks.length === 0) {
					ui.notify("No tasks found in plan.", "error");
					return;
				}

				// For now: run only the first task
				const taskSpec = tasks[0];
				ui.notify(`Starting workflow "${def.name}" on ${planPath}`, "info");

				const task = new Task(taskSpec, def, {
					cwd: ctx.cwd,
					baselineRef,
					steeringNotes: "",
					modelRuntime,
					ui,
					signal: controller.signal,
					agentDir: getAgentDir(),
					ctx,
				});

				const result: TaskResult = await task.run();

				if (result.success) {
					ui.notify("Workflow completed.", "info");
				} else {
					ui.notify(`Workflow failed: ${result.error?.message ?? "Unknown error"}`, "error");
					ui.notify("Any partial changes remain in your working tree (git diff to inspect).", "warning");
				}
			} catch (err) {
				if (err instanceof WorkflowAbort) {
					ui.notify(`Workflow stopped (${err.kind}): ${err.message}`, err.kind === "user" ? "warning" : "error");
					ui.notify("Any partial changes remain in your working tree (git diff to inspect).", "warning");
				} else {
					ui.notify(`Workflow error: ${(err as Error).message}`, "error");
				}
			} finally {
				ui.clear();
				activeController = undefined;
			}
		},
	});
}

function resolvePlanPath(arg: string, cwd: string): string | undefined {
	if (!arg) return undefined;
	return isAbsolute(arg) ? arg : join(cwd, arg);
}
