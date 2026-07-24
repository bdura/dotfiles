/**
 * Concrete instantiation: a Python project workflow.
 *
 * Pipeline (per task):
 *   implement → ruff → ty → pytest → validate → review → retro → done
 * Deterministic gates run ruff/ty/pytest; validate/review are agent-led verdicts.
 * Any gate failure routes back to the implementer with plaintext feedback.
 *
 * This file is the ONLY place that names ruff/ty/pytest or the concrete roles;
 * the framework stays domain-agnostic.
 */

import { StringEnum } from "@earendil-works/pi-ai";
import { type Static, Type } from "typebox";
import { agentVerdictGate, deterministicGate, fnGate } from "../framework/gates.ts";
import type { AgentRole, GateResult, State, WorkflowDefinition } from "../framework/types.ts";

// ---- verdict schemas ---------------------------------------------------------

const Issue = Type.Object({
	severity: StringEnum(["blocker", "major", "minor"]),
	description: Type.String({ description: "What is wrong" }),
	location: Type.Optional(Type.String({ description: "file:line or symbol, if applicable" })),
});

const ValidatorVerdict = Type.Object({
	verdict: StringEnum(["pass", "fail"]),
	issues: Type.Array(Issue, { description: "Concrete problems found in the change" }),
	summary: Type.String({ description: "One-paragraph rationale" }),
});

const ReviewerVerdict = Type.Object({
	verdict: StringEnum(["pass", "fail"]),
	goalMet: Type.Boolean({ description: "Does the change implement the task goal from the plan?" }),
	adheresToConventions: Type.Boolean({ description: "Does it follow the project's conventions and general good practice?" }),
	issues: Type.Array(Issue),
	summary: Type.String(),
});

// ---- verdict interpreters ----------------------------------------------------

function formatIssues(issues: Static<typeof Issue>[]): string {
	if (issues.length === 0) return "(no specific issues listed)";
	return issues
		.map((i) => `- [${i.severity}] ${i.description}${i.location ? ` (${i.location})` : ""}`)
		.join("\n");
}

function interpretValidator(v: Static<typeof ValidatorVerdict>): GateResult {
	const hasBlocker = v.issues.some((i) => i.severity === "blocker");
	const pass = v.verdict === "pass" && !hasBlocker;
	if (pass) return { pass: true, label: "validator: pass", structured: v };
	return {
		pass: false,
		label: `validator: fail (${v.issues.length} issue${v.issues.length === 1 ? "" : "s"})`,
		structured: v,
		feedback: ["Validation failed.", v.summary, "", "Issues:", formatIssues(v.issues)].join("\n"),
	};
}

function interpretReviewer(v: Static<typeof ReviewerVerdict>): GateResult {
	const pass = v.verdict === "pass" && v.goalMet && v.adheresToConventions;
	if (pass) return { pass: true, label: "reviewer: pass", structured: v };
	return {
		pass: false,
		label: "reviewer: fail",
		structured: v,
		feedback: [
			"Review failed.",
			v.summary,
			`goal met: ${v.goalMet} · adheres to conventions: ${v.adheresToConventions}`,
			"",
			"Issues:",
			formatIssues(v.issues),
		].join("\n"),
	};
}

// ---- deterministic gate commands (edit these for your project) ---------------

const RUFF_COMMAND = "ruff check .";
const TY_COMMAND = "ty check";
const PYTEST_COMMAND = "pytest -q";

const alwaysPass = fnGate(async () => ({ pass: true }));

export function buildPythonWorkflow(roles: Record<string, AgentRole>): WorkflowDefinition {
	const states: State[] = [
		{
			id: "implement",
			role: "implementer",
			transitions: [{ gate: alwaysPass, onPass: "ruff", onFail: "implement", maxLoops: 1 }],
		},
		{
			id: "ruff",
			role: "",
			transitions: [
				{ gate: deterministicGate({ name: "ruff", command: RUFF_COMMAND }), onPass: "ty", onFail: "implement", maxLoops: 3 },
			],
		},
		{
			id: "ty",
			role: "",
			transitions: [
				{ gate: deterministicGate({ name: "ty", command: TY_COMMAND }), onPass: "pytest", onFail: "implement", maxLoops: 3 },
			],
		},
		{
			id: "pytest",
			role: "",
			transitions: [
				{
					gate: deterministicGate({ name: "pytest", command: PYTEST_COMMAND, timeoutMs: 10 * 60_000 }),
					onPass: "validate",
					onFail: "implement",
					maxLoops: 3,
				},
			],
		},
		{
			id: "validate",
			role: "validator",
			verdict: { schema: ValidatorVerdict, maxReprompts: 2, interpret: interpretValidator },
			transitions: [
				{ gate: agentVerdictGate<typeof ValidatorVerdict>(interpretValidator), onPass: "review", onFail: "implement", maxLoops: 3 },
			],
		},
		{
			id: "review",
			role: "reviewer",
			verdict: { schema: ReviewerVerdict, maxReprompts: 2, interpret: interpretReviewer },
			transitions: [
				{ gate: agentVerdictGate<typeof ReviewerVerdict>(interpretReviewer), onPass: "retro", onFail: "implement", maxLoops: 2 },
			],
		},
		{
			id: "retro",
			role: "retro",
			transitions: [{ gate: alwaysPass, onPass: "done", onFail: "done", maxLoops: 1 }],
		},
		{ id: "done", role: "", transitions: [] },
	];

	return {
		name: "python-implement",
		roles,
		implementerRole: "implementer",
		states,
		initialState: "implement",
		globalBudget: 40,
	};
}
