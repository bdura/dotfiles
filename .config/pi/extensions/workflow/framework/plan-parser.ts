/**
 * Parse an implementation plan markdown file into an ordered task list
 * (decision #10). The plan is pre-structured by the user.
 *
 * Supported conventions (either may be used in a single file):
 *   1. Heading tasks:   `## Task: <title>` followed by the task body until the
 *      next `## Task:` / `## ` heading.
 *   2. Checklist tasks: top-level `- [ ] <title>` bullets; the body is any
 *      indented lines that follow until the next top-level bullet.
 *
 * Heading tasks take precedence when present.
 */

import { readFileSync } from "node:fs";
import type { TaskSpec } from "./types.ts";
import { WorkflowAbort } from "./types.ts";

const HEADING_TASK = /^#{2,3}\s*Task:\s*(.+?)\s*$/i;
const CHECKLIST_TASK = /^- \[[ xX]\]\s*(.+?)\s*$/;

export function parsePlan(planPath: string): TaskSpec[] {
	let raw: string;
	try {
		raw = readFileSync(planPath, "utf-8");
	} catch {
		throw new WorkflowAbort(`Could not read plan file: ${planPath}`, "error");
	}

	const lines = raw.split("\n");
	const headingTasks = parseHeadingTasks(lines);
	const tasks = headingTasks.length > 0 ? headingTasks : parseChecklistTasks(lines);

	if (tasks.length === 0) {
		throw new WorkflowAbort(
			`No tasks found in ${planPath}. Use '## Task: <title>' sections or '- [ ] <title>' checklist items.`,
			"error",
		);
	}
	return tasks;
}

function parseHeadingTasks(lines: string[]): TaskSpec[] {
	const tasks: TaskSpec[] = [];
	let current: { title: string; body: string[] } | null = null;
	const flush = () => {
		if (current) tasks.push(toTask(tasks.length, current.title, current.body.join("\n")));
	};
	for (const line of lines) {
		const m = line.match(HEADING_TASK);
		if (m) {
			flush();
			current = { title: m[1], body: [] };
		} else if (current) {
			// A new top-level (non-task) heading ends the current task body.
			if (/^#{1,2}\s+\S/.test(line) && !HEADING_TASK.test(line)) {
				flush();
				current = null;
			} else {
				current.body.push(line);
			}
		}
	}
	flush();
	return tasks;
}

function parseChecklistTasks(lines: string[]): TaskSpec[] {
	const tasks: TaskSpec[] = [];
	let current: { title: string; body: string[] } | null = null;
	const flush = () => {
		if (current) tasks.push(toTask(tasks.length, current.title, current.body.join("\n")));
	};
	for (const line of lines) {
		const m = line.match(CHECKLIST_TASK);
		if (m) {
			flush();
			current = { title: m[1], body: [] };
		} else if (current) {
			if (/^\S/.test(line) && line.trim().length > 0) {
				// A new non-indented, non-empty line ends the current task.
				flush();
				current = null;
			} else {
				current.body.push(line);
			}
		}
	}
	flush();
	return tasks;
}

function toTask(index: number, title: string, body: string): TaskSpec {
	const trimmed = body.trim();
	return {
		id: `task-${index + 1}`,
		title,
		body: trimmed.length > 0 ? `${title}\n\n${trimmed}` : title,
	};
}
