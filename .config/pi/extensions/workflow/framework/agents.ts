/**
 * Discover markdown agent files (frontmatter + body) and build AgentRole records.
 * Adapted from examples/extensions/subagent/agents.ts, simplified to a fixed dir.
 */

import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { parseFrontmatter } from "@earendil-works/pi-coding-agent";
import type { AgentRole } from "./types";
import { WorkflowAbort } from "./types";

/** Load every *.md in `dir` as an AgentRole keyed by frontmatter `name`. */
export function discoverRoles(dir: string): Record<string, AgentRole> {
	const roles: Record<string, AgentRole> = {};
	let entries: string[];
	try {
		entries = readdirSync(dir).filter((f) => f.endsWith(".md"));
	} catch {
		throw new WorkflowAbort(`Could not read agents directory: ${dir}`, "error");
	}

	for (const file of entries) {
		const filePath = join(dir, file);
		const content = readFileSync(filePath, "utf-8");
		const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);
		if (!frontmatter.name) continue;
		const tools = frontmatter.tools
			?.split(",")
			.map((t) => t.trim())
			.filter(Boolean);
		roles[frontmatter.name] = {
			name: frontmatter.name,
			model: frontmatter.model,
			tools: tools && tools.length > 0 ? tools : undefined,
			systemPrompt: body.trim(),
		};
	}
	return roles;
}

/** Verify every role referenced by the workflow exists; abort with a clear message otherwise. */
export function assertRolesPresent(roles: Record<string, AgentRole>, required: string[]): void {
	const missing = required.filter((r) => r && !roles[r]);
	if (missing.length > 0) {
		throw new WorkflowAbort(
			`Missing agent definitions for role(s): ${missing.join(", ")}. Add matching *.md files under agents/.`,
			"error",
		);
	}
}
