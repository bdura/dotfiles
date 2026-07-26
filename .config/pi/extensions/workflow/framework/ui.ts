/**
 * Live widget dashboard + milestone session entries (decision #12).
 */

import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import type { GateResult, UsageTotals } from "./types";

const WIDGET_KEY = "workflow";
const STATUS_KEY = "workflow";
const ENTRY_TYPE = "workflow-milestone";
const MAX_ACTIVITY = 8;

export interface Milestone {
	kind: "state" | "gate" | "escalation" | "start" | "end" | "error";
	task: string;
	state?: string;
	text: string;
	pass?: boolean;
}

export class WorkflowUI {
	private taskTitle = "";
	private state = "";
	private loopInfo = "";
	private budget = "";
	private lastGate = "";
	private activity: string[] = [];

	constructor(
		private readonly pi: ExtensionAPI,
		private readonly ctx: ExtensionCommandContext,
	) {}

	setTask(title: string) {
		this.taskTitle = title;
		this.activity = [];
		this.lastGate = "";
		this.render();
	}

	setState(state: string) {
		this.state = state;
		this.render();
	}

	setLoop(text: string) {
		this.loopInfo = text;
		this.render();
	}

	setBudget(used: number, total: number) {
		this.budget = `${used}/${total}`;
		this.render();
	}

	setGate(result: GateResult) {
		this.lastGate = `${result.pass ? "✓" : "✗"} ${result.label ?? (result.pass ? "pass" : "fail")}`;
		this.render();
	}

	pushActivity(line: string) {
		this.activity.push(line);
		if (this.activity.length > MAX_ACTIVITY) this.activity.shift();
		this.render();
	}

	private render() {
		const lines = [
			`⚙ Workflow — ${this.taskTitle}`,
			`  state: ${this.state}   loops: ${this.loopInfo || "-"}   budget: ${this.budget || "-"}   gate: ${this.lastGate || "-"}`,
			...this.activity.map((a) => `    ${a}`),
		];
		this.ctx.ui.setWidget(WIDGET_KEY, lines);
		this.ctx.ui.setStatus(STATUS_KEY, `workflow · ${this.state}`);
	}

	milestone(m: Milestone) {
		this.pi.appendEntry<Milestone>(ENTRY_TYPE, m);
	}

	notify(message: string, type: "info" | "warning" | "error" = "info") {
		this.ctx.ui.notify(message, type);
	}

	async escalate(reason: string): Promise<"retry" | "abort" | "accept"> {
		const choice = await this.ctx.ui.select(`Workflow paused: ${reason}`, [
			"Retry (reset the counter and continue)",
			"Abort the workflow",
			"Accept and continue (treat current gate as pass)",
		]);
		if (choice?.startsWith("Retry")) return "retry";
		if (choice?.startsWith("Accept")) return "accept";
		return "abort";
	}

	summarizeUsage(u: UsageTotals): string {
		return `${u.turns} turns · ↑${u.input} ↓${u.output} · $${u.cost.toFixed(4)}`;
	}

	clear() {
		this.ctx.ui.setWidget(WIDGET_KEY, undefined);
		this.ctx.ui.setStatus(STATUS_KEY, undefined);
	}
}
