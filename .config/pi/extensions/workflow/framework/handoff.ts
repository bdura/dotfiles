/**
 * Git ground-truth helpers (decision #3, #4) and delimited-block extraction for
 * in-memory handoff / steering notes (decision #13: no files written to the repo).
 */

import { runCommand } from "./exec";
import { WorkflowAbort } from "./types";

const DIFF_CAP = 100 * 1024; // cap diff injected into prompts

async function git(args: string[], cwd: string, signal: AbortSignal) {
	return runCommand("git", { cwd, signal, args });
}

/** Ensure we are in a git repo with a clean working tree (decision #4). */
export async function assertCleanTree(cwd: string, signal: AbortSignal): Promise<void> {
	const inside = await git(["rev-parse", "--is-inside-work-tree"], cwd, signal);
	if (inside.exitCode !== 0 || inside.stdout.trim() !== "true") {
		throw new WorkflowAbort(
			"Not a git repository. The workflow requires a git repo to diff against a baseline.",
			"error",
		);
	}
	const status = await git(["status", "--porcelain"], cwd, signal);
	if (status.stdout.trim().length > 0) {
		throw new WorkflowAbort(
			"Working tree is not clean. Commit or stash your changes before running the workflow.",
			"error",
		);
	}
}

/** Record the starting HEAD as the baseline for all diffs. */
export async function getBaselineRef(cwd: string, signal: AbortSignal): Promise<string> {
	const head = await git(["rev-parse", "HEAD"], cwd, signal);
	if (head.exitCode !== 0) {
		throw new WorkflowAbort("Could not resolve HEAD. The repo has no commits yet.", "error");
	}
	return head.stdout.trim();
}

/** `git diff <baselineRef>` including untracked files, capped for prompt injection. */
export async function computeDiff(cwd: string, baselineRef: string, signal: AbortSignal): Promise<string> {
	const tracked = await git(["diff", baselineRef], cwd, signal);
	// Include untracked files as additions.
	const untracked = await git(["ls-files", "--others", "--exclude-standard"], cwd, signal);
	let extra = "";
	for (const file of untracked.stdout.split("\n").map((l) => l.trim()).filter(Boolean)) {
		const d = await git(["diff", "--no-index", "/dev/null", file], cwd, signal);
		extra += d.stdout;
	}
	let combined = tracked.stdout + (extra ? `\n${extra}` : "");
	if (combined.length > DIFF_CAP) {
		combined = `${combined.slice(0, DIFF_CAP)}\n\n[diff truncated at ${DIFF_CAP} bytes]`;
	}
	return combined || "(no changes yet)";
}

/**
 * Extract a delimited block from an agent's final text output.
 * Agents are instructed to emit `### <MARKER>` followed by the block content
 * as the last section of their reply.
 */
export function extractBlock(text: string, marker: string): string | undefined {
	const re = new RegExp(`#{1,6}\\s*${marker}\\s*\\n([\\s\\S]*)$`, "i");
	const m = text.match(re);
	if (!m) return undefined;
	return m[1].trim() || undefined;
}
