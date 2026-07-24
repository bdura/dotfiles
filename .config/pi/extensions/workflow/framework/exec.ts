/**
 * Minimal command execution with AbortSignal support and output truncation.
 * Used for git operations and deterministic gate commands.
 */

import { spawn } from "node:child_process";

export interface ExecOutcome {
	exitCode: number;
	stdout: string;
	stderr: string;
	/** True if the process was killed via the abort signal. */
	aborted: boolean;
	/** True if output was truncated. */
	truncated: boolean;
}

const MAX_OUTPUT_BYTES = 200 * 1024; // 200 KB per stream before truncation

export interface RunCommandOptions {
	cwd: string;
	signal: AbortSignal;
	timeoutMs?: number;
	/** Split a raw command string; when provided, `command` is treated as argv[0]. */
	args?: string[];
}

/**
 * Run a command. When `args` is omitted, `command` is executed through the shell
 * so instantiations can write natural command lines like "ruff check .".
 */
export function runCommand(command: string, opts: RunCommandOptions): Promise<ExecOutcome> {
	return new Promise((resolve) => {
		const useShell = opts.args === undefined;
		const child = useShell
			? spawn(command, { cwd: opts.cwd, shell: true, stdio: ["ignore", "pipe", "pipe"] })
			: spawn(command, opts.args, { cwd: opts.cwd, shell: false, stdio: ["ignore", "pipe", "pipe"] });

		let stdout = "";
		let stderr = "";
		let truncated = false;
		let aborted = false;
		let settled = false;

		const append = (buf: string, chunk: string): string => {
			if (buf.length >= MAX_OUTPUT_BYTES) {
				truncated = true;
				return buf;
			}
			const next = buf + chunk;
			if (next.length > MAX_OUTPUT_BYTES) {
				truncated = true;
				return next.slice(0, MAX_OUTPUT_BYTES);
			}
			return next;
		};

		child.stdout.on("data", (d) => {
			stdout = append(stdout, d.toString());
		});
		child.stderr.on("data", (d) => {
			stderr = append(stderr, d.toString());
		});

		const onAbort = () => {
			aborted = true;
			child.kill("SIGTERM");
		};
		if (opts.signal.aborted) onAbort();
		else opts.signal.addEventListener("abort", onAbort, { once: true });

		let timer: NodeJS.Timeout | undefined;
		if (opts.timeoutMs) {
			timer = setTimeout(() => {
				aborted = true;
				child.kill("SIGTERM");
			}, opts.timeoutMs);
		}

		const finish = (exitCode: number) => {
			if (settled) return;
			settled = true;
			if (timer) clearTimeout(timer);
			opts.signal.removeEventListener("abort", onAbort);
			resolve({ exitCode, stdout, stderr, aborted, truncated });
		};

		child.on("error", (err) => {
			stderr = append(stderr, `\n${(err as Error).message}`);
			finish(127);
		});
		child.on("close", (code) => finish(code ?? 1));
	});
}
