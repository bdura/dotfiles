/**
 * Gate primitives (decision #5). Both deterministic and agent-led gates return
 * the uniform `GateResult` so the engine routes transitions identically.
 */

import type { Static, TSchema } from "typebox";
import { runCommand } from "./exec";
import type { Gate, GateResult, RunContext } from "./types";

export interface DeterministicGateSpec {
	/** Human label for the dashboard, e.g. "ruff". */
	name: string;
	/** Shell command line, e.g. "ruff check .". */
	command: string;
	timeoutMs?: number;
	/** Override the default exit-code interpretation. */
	interpret?: (r: { exitCode: number; stdout: string; stderr: string }) => GateResult;
}

/**
 * A deterministic gate that runs a shell command (or array of commands).
 * For a single command: passes iff exit code 0.
 * For an array: runs sequentially, stops at first failure, passes only if all pass.
 * On failure, the combined stderr/stdout becomes the feedback fed to the
 * implementer verbatim (decision: feedback stays plaintext in v1).
 */
export function deterministicGate(spec: DeterministicGateSpec | DeterministicGateSpec[]): Gate {
	return async (ctx: RunContext): Promise<GateResult> => {
		const specs = Array.isArray(spec) ? spec : [spec];
		
		for (const s of specs) {
			const r = await runCommand(s.command, {
				cwd: ctx.cwd,
				signal: ctx.signal,
				timeoutMs: s.timeoutMs,
			});
			
			if (s.interpret) {
				const interpreted = s.interpret(r);
				if (!interpreted.pass) {
					return interpreted;
				}
				continue;
			}
			
			if (r.exitCode !== 0) {
				const output = [r.stdout, r.stderr].filter(Boolean).join("\n").trim();
				return {
					pass: false,
					label: `${s.name}: failed (exit ${r.exitCode})`,
					feedback: [
						`The \`${s.name}\` check failed (\`${s.command}\`, exit code ${r.exitCode}).`,
						"Fix the issues below, then finish.",
						"",
						output || "(no output captured)",
					].join("\n"),
					structured: { exitCode: r.exitCode },
				};
			}
		}
		
		return { pass: true, label: specs.length === 1 ? `${specs[0].name}: ok` : "all cli checks passed" };
	};
}

/** An arbitrary JS predicate gate. */
export function fnGate(fn: (ctx: RunContext) => Promise<GateResult>): Gate {
	return fn;
}

/**
 * A gate that reads the structured verdict captured by the state's agent
 * (via the submit_verdict tool) and maps it to a GateResult. The runner
 * guarantees a verdict is present (or aborts), so `interpret` always receives one.
 */
export function agentVerdictGate<S extends TSchema>(interpret: (verdict: Static<S>) => GateResult): Gate {
	return async (ctx: RunContext): Promise<GateResult> => {
		const verdict = ctx.lastRun?.verdict as Static<S> | undefined;
		if (verdict === undefined) {
			// Defensive: should be unreachable because the runner enforces submission.
			return { pass: false, label: "verdict missing", feedback: "No verdict was produced." };
		}
		return interpret(verdict);
	};
}
