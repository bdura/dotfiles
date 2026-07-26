# Implementation Plan: State-Machine Multi-Agent Workflow Extension

## 1. Overview

Build a Pi extension that runs a **deterministic, state-machine-driven multi-agent
workflow** for implementing a pre-written plan. Unlike the `subagent` example (where the
host LLM *chooses* to delegate), this extension is an **orchestrator**: a slash command
drives a fixed state machine to completion, spawning specialized sub-agents and gating
transitions between them with deterministic checks (lint/type/test) and agent-led
structured verdicts.

The code is split into two layers:

- A reusable **framework** (`framework/`): the engine, the sub-agent runner, gate
  primitives, handoff/steering artifacts, and TUI rendering. It knows nothing about
  Python, ruff, or any specific agent.
- A concrete **instantiation** (`workflows/` + `agents/`): a typed `WorkflowDefinition`
  plus markdown agent files that wire up a specific pipeline (e.g. a Python project using
  ruff/ty/pytest and validator/reviewer verdicts).

### The pipeline (per task)

```text
                      ┌──────────── fail (feedback → implementer, same session) ───────────┐
                      │                                                                     │
  task ──► implementer ──► [ruff] ──► [ty] ──► [pytest] ──► validator ──► reviewer ──► retro ──► next task
                            (deterministic gates)            (verdict)     (verdict)   (notes)
```

- Any failing gate routes back to the **implementer** with the failure feedback as plain
  text, delivered into the *same* implementer sub-session (fix-forward).
- The implementer works on **one well-defined task at a time**, taken in order from a
  pre-structured task list parsed from the plan.
- `retro` runs after each task; its notes accumulate into a steering file that is injected
  into subsequent tasks' agents.

## 2. Design decisions (authoritative — do not relitigate)

These were settled deliberately. Implement to these; do not redesign.

| # | Area | Decision |
|---|------|----------|
| 1 | Execution substrate | **SDK in-process sub-sessions.** Use `createAgentSession({ sessionManager: SessionManager.inMemory() })`, one `AgentSession` per role invocation, each with its own model/tools/system prompt and isolated context. Share one `ModelRuntime`. |
| 2 | Trigger / driver | **Slash command** (`/workflow <plan-path>`) whose handler runs the entire state machine to completion. The host LLM is not used for orchestration. |
| 3 | State handoff | **Filesystem/git is the source of truth.** Downstream agents read the repo + `git diff` + a compact structured **handoff note** each agent writes. No transcript passing between roles. |
| 4 | Working tree | **Keep the current branch.** Require a **clean working tree** as a precondition (abort if dirty). Diff everything against the starting `HEAD`. No branch switching, no stash, **no rollback** (implementer fixes forward). |
| 5 | Gate contract | **One uniform `GateResult` contract** for both deterministic and agent gates. |
| 6 | Verdict enforcement | Agent verdicts submitted via a **`submit_verdict` terminating tool** (`terminate: true`). If the agent ends its turn without calling it, **re-prompt up to N times, then abort the whole workflow**. |
| 7 | Loop continuity | On gate failure, the implementer resumes in the **same sub-session** (feedback delivered as a follow-up message). Fix-forward. |
| 8 | Loop limits | **Per-transition loop caps + a global iteration budget.** On exhaustion, **escalate to the human** via `ctx.ui.select` (retry / abort / accept-and-continue). |
| 9 | Instantiation form | **Typed `WorkflowDefinition` (TS)** built with framework helpers (a gate may be an arbitrary JS fn or a command spec) **+ markdown agent files** with YAML frontmatter. |
| 10 | Plan → tasks | Plan is a **pre-structured ordered task list** (parsed from markdown checklist). Outer loop iterates tasks in order; full pipeline runs per task. No decomposer agent in v1. |
| 11 | Retro cadence | **Per task.** Notes accumulate into a steering file that is prepended to subsequent agents' context and also update project docs. |
| 12 | Observability | **Live widget dashboard** (`ctx.ui.setWidget`/`setStatus`) + **milestone session entries** (`pi.appendEntry`) at each transition/gate. |
| 13 | Persistence | **In-memory only, no resume** in v1. Abort ends the run; only git changes + milestone entries persist. |

### Explicitly out of scope for v1

- Low-latency model to parse feedback into structured form (future; feedback stays plaintext).
- A plan-decomposer agent (tasks are pre-structured in the plan).
- Resumability / crash recovery.
- Parallelism (the machine is strictly sequential; no concurrency concerns).
- Language auto-detection (the instantiation names its gate commands explicitly).

## 3. Prerequisites: read these Pi docs first

Resolve paths under the Pi monorepo docs/examples directories.

- `docs/extensions.md` — `pi.registerCommand`, `ExtensionCommandContext` (has
  `waitForIdle`, session control), `ctx.ui` (`select`, `confirm`, `notify`, `setStatus`,
  `setWidget`), `pi.appendEntry`, `pi.registerTool`/`defineTool`, `terminate: true`.
- `docs/sdk.md` — `createAgentSession`, `SessionManager.inMemory`, `ModelRuntime.create`,
  `getModel`, `session.subscribe(...)` events, `session.prompt`, `session.followUp`,
  `session.dispose()`, `customTools`, `systemPromptOverride` via `DefaultResourceLoader`.
- `examples/extensions/subagent/` — reference for spawning agents and streaming their tool
  calls into UI. Note: it uses **subprocesses**; we use the **SDK** instead, but the
  event→UI rendering and usage-tracking patterns transfer directly. `agents.ts` shows the
  `parseFrontmatter` + agent-discovery pattern to reuse for our markdown agent files.
- `examples/extensions/structured-output.ts` — the exact `terminate: true` pattern for the
  `submit_verdict` tool (capture params in `execute`, end the turn on the tool call).
- `examples/extensions/todo.ts` — custom rendering + state persistence + `/command` patterns.
- `examples/extensions/status-line.ts` and `widget-placement.ts` — `setStatus`/`setWidget` usage.

Key API facts (already verified against docs — trust these):

- `createAgentSession` can be called from inside an extension command handler. It returns
  `{ session }`. Always `session.dispose()` when done with a role invocation.
- `defineTool({ name, label, description, parameters, execute })` where `execute` returns
  `{ content, details, terminate? }`. Setting `terminate: true` ends the agent turn on the
  tool call (no extra LLM round-trip).
- `session.subscribe(listener)` returns an unsubscribe fn; events include
  `tool_execution_start/end`, `message_end`, `agent_end` with usage on assistant messages.
- Feedback delivery into a live session: `await session.followUp(text)` (or
  `session.prompt(text)` when idle).
- `ModelRuntime.create()` once, reuse for all sub-sessions; resolve models with
  `getModel(provider, id)` or `modelRuntime.getModel(...)`.
- Use `parseFrontmatter` and `CONFIG_DIR_NAME` from `@earendil-works/pi-coding-agent`.

## 4. Directory layout

```text
extensions/workflow/
├── plan.md                     # this file
├── index.ts                    # extension entry: registers /workflow command + wiring
├── framework/
│   ├── types.ts                # WorkflowDefinition, AgentRole, State, Transition, GateResult, RunContext
│   ├── engine.ts               # state machine driver (task loop + phase transitions + limits + escalation)
│   ├── runner.ts               # createAgentSession per role invocation; event → dashboard; feedback delivery
│   ├── gates.ts                # deterministicGate(), agentVerdictGate(), verdict tool + retry/abort wrapper
│   ├── handoff.ts              # handoff note + steering file read/write; git diff/clean-tree helpers
│   ├── agents.ts               # markdown agent discovery + frontmatter parsing (adapt subagent/agents.ts)
│   ├── plan.ts                 # parse the plan markdown into an ordered task list
│   └── ui.ts                   # live widget dashboard + milestone appendEntry helpers
├── workflows/
│   └── python.ts               # the concrete WorkflowDefinition (ruff/ty/pytest + validator/reviewer verdicts)
└── agents/
    ├── implementer.md          # frontmatter: name/model/tools + system prompt
    ├── validator.md
    ├── reviewer.md
    └── retro.md
```

## 5. Framework contracts (`framework/types.ts`)

Define these types precisely; the engine and instantiation depend on them.

```typescript
import type { Static, TSchema } from "typebox";

/** Uniform result every gate produces. */
export interface GateResult {
  pass: boolean;
  /** Plaintext fed back to the implementer on failure. Required when pass === false. */
  feedback?: string;
  /** Optional machine-readable payload (e.g. parsed verdict) for UI/logging. */
  structured?: unknown;
}

/** Immutable per-run context passed to gates and the runner. */
export interface RunContext {
  cwd: string;
  baselineRef: string;          // git rev of the clean starting HEAD
  task: TaskSpec;               // the current task
  taskIndex: number;            // 0-based
  taskCount: number;
  steeringNotes: string;        // accumulated retro notes injected into agents
  workspaceDir: string;         // dir for handoff note + steering file (in-memory-backed OK)
  signal?: AbortSignal;         // from the command ctx; propagate to sub-sessions/git
  diff(): Promise<string>;      // `git diff <baselineRef>` convenience
}

export type Gate = (ctx: RunContext) => Promise<GateResult>;

export interface AgentRole {
  name: string;                 // matches the markdown agent file `name`
  model?: string;               // provider/id; falls back to host default if omitted
  tools?: string[];             // built-in tool allowlist for this role
  systemPrompt: string;         // from markdown body (+ steering notes prepended at runtime)
}

/** A phase in the machine. Terminal when transitions === []. */
export interface State {
  id: string;                   // e.g. "implement", "validate", "review", "retro"
  role: string;                 // AgentRole.name to run for this state (or none for pure gate states)
  transitions: Transition[];
}

export interface Transition {
  gate: Gate;                   // evaluated after the state's agent (if any) finishes
  onPass: string;               // next state id
  onFail: string;               // state id to route to on failure (usually "implement")
  maxLoops: number;             // per-transition loop cap
}

export interface WorkflowDefinition {
  name: string;
  roles: Record<string, AgentRole>;   // resolved from markdown files
  states: State[];
  initialState: string;
  globalBudget: number;               // max total phase executions per task
}

export interface TaskSpec {
  id: string;
  title: string;
  body: string;                 // full task text handed to the implementer
}
```

Notes:

- `agentVerdictGate` needs a Typebox schema; keep the verdict schema in the instantiation.
- A "deterministic gate state" can be modeled either as a `State` with `role: ""` (no agent,
  just run the gate) or by attaching multiple transitions with gates to the implement state.
  **Recommended:** model each deterministic check (ruff, ty, pytest) as its own no-agent
  `State` whose single transition runs the command gate; `onFail: "implement"`,
  `onPass: <next check>`. This keeps the graph explicit and the dashboard readable.

## 6. Framework components

### 6.1 `framework/plan.ts` — plan parsing

- Input: path to a markdown plan. Output: ordered `TaskSpec[]`.
- Parse a checklist / task-list convention. Recommended: top-level `## Task: <title>`
  sections, or `- [ ] <title>` bullets with following indented body. Pick one convention,
  document it at the top of the parser, and validate: **error out with a clear message if
  no tasks are found** (a mis-parsed plan must not silently run zero tasks).
- Each task's `body` becomes the implementer's task text.

### 6.2 `framework/agents.ts` — agent discovery

- Adapt `subagent/agents.ts`: read `extensions/workflow/agents/*.md`, `parseFrontmatter`
  for `name`, `model`, `tools`; markdown body is the system prompt.
- Build `Record<string, AgentRole>` keyed by name. Error if a role referenced by a `State`
  is missing.

### 6.3 `framework/runner.ts` — role invocation

Responsibilities:

- `runRole(role, opts): Promise<RoleRunResult>` — creates an `AgentSession` via
  `createAgentSession`:
  - `model`: resolve `role.model` through `ModelRuntime`; fallback to host default.
  - `tools`: `role.tools`; validator/reviewer get read-only tools **only** plus the
    `submit_verdict` custom tool (nothing else productive — see decision #6).
  - `systemPromptOverride`: `role.systemPrompt` with the **steering notes prepended**.
  - `customTools`: include `submit_verdict` for verdict roles.
  - `sessionManager: SessionManager.inMemory(cwd)`.
  - **Important:** pass a minimal `ResourceLoader`/options so the sub-session does **not**
    recursively load this workflow extension. Verify this in the spike (§8). If needed,
    construct a `DefaultResourceLoader` with extension discovery disabled or an override.
- Subscribe to session events → forward tool calls / text to the dashboard (§6.6) and
  accumulate usage (turns, tokens, cost) like `subagent/index.ts`.
- Provide the implementer session as a **persistent handle** so loop-backs can
  `session.followUp(feedback)` into the same session (decision #7). Other roles are
  one-shot: run, capture verdict/output, `dispose()`.
- Propagate `ctx.signal` (from the command) to abort sub-sessions on Esc/Ctrl+C.
- Always `dispose()` sessions when finished (except the implementer, which is disposed at
  the end of the task).

`RoleRunResult` should carry: final text/output, usage, and (for verdict roles) the
captured verdict via the tool closure.

### 6.4 `framework/gates.ts` — gate primitives

```typescript
// Deterministic gate from a shell command (e.g. "ruff check .").
export function deterministicGate(spec: {
  command: string;
  // Map exit code + stdout/stderr to a GateResult. Default: pass iff exitCode === 0,
  // feedback = combined stderr/stdout on failure.
  interpret?: (r: { exitCode: number; stdout: string; stderr: string }) => GateResult;
}): Gate;

// Deterministic gate from an arbitrary JS predicate.
export function fnGate(fn: (ctx: RunContext) => Promise<GateResult>): Gate;

// Agent-led verdict gate. The verdict is produced by the role that ran for the state,
// via the submit_verdict tool. This gate just reads the captured verdict.
export function agentVerdictGate<S extends TSchema>(schema: S, opts: {
  // Map the structured verdict to pass/feedback.
  interpret: (verdict: Static<S>) => GateResult;
  maxReprompts: number;     // decision #6: re-prompt this many times…
}): Gate;
```

`submit_verdict` tool (built by the framework, one instance per verdict role invocation):

- `defineTool` with the role's verdict `schema` as `parameters`.
- `execute` captures the verdict into a closure variable and returns `{ terminate: true }`.
- Verdict-enforcement wrapper (decision #6): after the role's turn ends, if no verdict was
  captured, `session.followUp("You must call submit_verdict now …")` and re-run; repeat up
  to `maxReprompts`. If still absent → throw a `WorkflowAbort` (the engine surfaces it and
  stops the run). Never fail-open.

Command execution: run gate commands in `ctx.cwd`, honoring `ctx.signal`. Use the same
robust output truncation approach as `subagent`/`truncated-tool` for large outputs.

### 6.5 `framework/handoff.ts` — artifacts + git

- `assertCleanTree(cwd)` — precondition check (decision #4). Abort with a clear message if
  `git status --porcelain` is non-empty or not a git repo.
- `getBaselineRef(cwd)` — record starting `HEAD`.
- `diff(cwd, baselineRef)` — `git diff <ref>` (used by validator/reviewer/gates).
- Handoff note: each agent writes a compact structured note (files touched, decisions,
  assumptions). Store under `workspaceDir`; downstream agents read it. Keep it small.
- Steering file: `appendSteering(note)` accumulates retro notes; `readSteering()` returns
  the text prepended to subsequent agents' system prompts (decision #11).

### 6.6 `framework/ui.ts` — observability (decision #12)

- Live dashboard via `ctx.ui.setWidget("workflow", lines)` and `ctx.ui.setStatus`:
  current task `i/N`, current state, per-transition loop counters, global budget used, last
  `GateResult` (pass/fail + short reason), and streaming sub-agent tool calls (last N).
- Milestone log via `pi.appendEntry(...)` at each transition and gate result, so the
  session transcript keeps a permanent audit trail. Consider a custom entry renderer for
  readability (see `entry-renderer.ts`).
- Clear the widget on completion/abort.

### 6.7 `framework/engine.ts` — the driver

Algorithm:

```text
assertCleanTree(cwd); baselineRef = getBaselineRef(cwd)
tasks = parsePlan(planPath)                       // error if empty
for (taskIndex, task) in tasks:
    steeringNotes = readSteering()
    build RunContext
    state = def.initialState
    loopCounts = {}                               // per-transition
    budgetUsed = 0
    persistentImplementerSession = null
    while state is not terminal:
        role = def.roles[state.role]  (may be none for pure gate states)
        if role:
            if role is implementer and persistentImplementerSession exists:
                followUp(feedback) into it        // fix-forward (decision #7)
            else:
                run role (fresh session); if implementer, keep the handle
        transition = state.transitions[...]       // evaluate its gate
        result = await transition.gate(runCtx)
        appendMilestone(state, result); updateDashboard()
        budgetUsed++
        if budgetUsed > def.globalBudget: escalate("budget")   // decision #8
        if result.pass:
            state = transition.onPass
        else:
            loopCounts[transitionKey]++
            if loopCounts[transitionKey] > transition.maxLoops:
                escalate("loop cap") → {retry: reset counter | abort | accept: treat as pass}
            else:
                feedback = result.feedback
                state = transition.onFail          // usually "implement"
    dispose implementer session
    // retro state already ran as part of the graph; its note appended to steering
finish: clear dashboard, notify summary
```

- `escalate(reason)` → `ctx.ui.select("<reason> — how to proceed?", ["Retry", "Abort", "Accept & continue"])`.
  Abort throws `WorkflowAbort`. Accept treats the current gate as pass. Retry resets the
  relevant counter.
- `WorkflowAbort` and any sub-session error propagate up; the command handler catches,
  clears UI, notifies, and stops. Working tree is left as-is; tell the user (decision #4).
- Honor `ctx.signal` throughout: on Esc, dispose the active sub-session and stop cleanly.

## 7. Extension entry (`index.ts`) + instantiation

### 7.1 `index.ts`

- `export default function (pi: ExtensionAPI)`.
- Create `ModelRuntime` lazily (in the command handler or `session_start`), reuse it.
- `pi.registerCommand("workflow", { description, handler })`:
  - Parse args → plan path (default to a conventional location if omitted).
  - Load agent roles (`framework/agents.ts`), load the `WorkflowDefinition`
    (`workflows/python.ts`), inject discovered roles.
  - Build UI helpers bound to `ctx`/`pi`.
  - Run `engine.run(def, { planPath, cwd: ctx.cwd, ui, modelRuntime, signal: ctx.signal })`.
  - Wrap in try/catch for `WorkflowAbort` and errors; always clear the dashboard.
- Use `ExtensionCommandContext` capabilities (it extends `ExtensionContext`): `ctx.ui.*`,
  `ctx.cwd`, `ctx.signal`. Do **not** capture stale session objects across any session
  replacement (we don't switch sessions here, so this is low risk).

### 7.2 `workflows/python.ts` (the instantiation)

- Import framework gate helpers + Typebox.
- Define verdict schemas:
  - `validatorVerdict = Type.Object({ verdict: StringEnum(["pass","fail"]), issues: Type.Array(Type.Object({ severity, description, location? })), summary: Type.String() })`
  - `reviewerVerdict` similar, plus adherence-to-plan/principles fields.
- Build the state graph:
  - `implement` (role: implementer) → transition gate = trivial pass → `ruff`.
  - `ruff` (no role) → `deterministicGate({ command: "ruff check ." })`, onPass `ty`, onFail `implement`, maxLoops e.g. 3.
  - `ty` → `deterministicGate({ command: "ty" })`, onPass `pytest`, onFail `implement`.
  - `pytest` → `deterministicGate({ command: "pytest -q" })`, onPass `validate`, onFail `implement`.
  - `validate` (role: validator) → `agentVerdictGate(validatorVerdict, …)`, onPass `review`, onFail `implement`.
  - `review` (role: reviewer) → `agentVerdictGate(reviewerVerdict, …)`, onPass `retro`, onFail `implement`.
  - `retro` (role: retro) → gate that always passes after writing steering notes → terminal.
- Set `globalBudget` and per-transition `maxLoops`. Keep CLI-gate caps low (risk #2 in §9).

### 7.3 Agent markdown files (`agents/*.md`)

Frontmatter `name`, `model`, `tools`; body = system prompt.

- `implementer.md` — full coding tools (`read, write, edit, bash`). Prompt: implement the
  single given task, keep changes scoped, write a handoff note.
- `validator.md` — **read-only** tools (`read, grep, find, ls, bash` for running nothing
  destructive) **+ submit_verdict**. Prompt: check correctness/validity of the diff; you
  MUST end by calling submit_verdict.
- `reviewer.md` — read-only + submit_verdict. Prompt: check the diff against the task goal
  and project conventions; MUST call submit_verdict.
- `retro.md` — `read, write, edit` (docs only). Prompt: update docs and append concise
  implementation notes/gotchas for future tasks.

## 8. Recommended build order

1. **Spike (de-risk first):** prove `createAgentSession` runs cleanly *nested inside an
   extension command*, with a `submit_verdict` terminating tool whose verdict is captured
   in a closure, and confirm the sub-session does **not** recursively load this extension.
   This validates decisions #1 and #6 and risk #5 before building the engine.
2. `framework/types.ts` — lock the contracts.
3. `framework/handoff.ts` — clean-tree check, baseline ref, diff, steering file.
4. `framework/agents.ts` + `framework/plan.ts` — discovery + parsing (+ empty-plan error).
5. `framework/runner.ts` — role invocation + persistent implementer session + event wiring.
6. `framework/gates.ts` — deterministic + verdict gates + retry/abort wrapper.
7. `framework/ui.ts` — dashboard + milestone entries.
8. `framework/engine.ts` — the driver loop, limits, escalation.
9. `index.ts` — command wiring.
10. `workflows/python.ts` + `agents/*.md` — the instantiation.
11. End-to-end test on a tiny Python repo with a 2-task plan (one task deliberately failing
    a gate to exercise the loop-back + escalation paths).

## 9. Risks & mitigations (carry these into implementation)

1. **Language/gate awareness is instantiation-only.** The framework never detects "Python."
   New language = new file under `workflows/`. Keep the framework free of tool names.
2. **Implementer context growth** across fix-forward loops (decision #7). Mitigate with low
   per-transition `maxLoops` on the CLI gates; the global budget backstops.
3. **No forced tool-choice.** Verdict reliability rests on prompt discipline + the
   retry-then-abort wrapper. Give verdict roles *nothing* to do except read + submit_verdict.
4. **Clean-tree precondition + no rollback + fix-forward** means a failed/aborted run leaves
   partial edits in the working tree. This is fine (git diff shows all), but the command
   MUST clearly tell the user at abort/escalation.
5. **Nested `createAgentSession` resource loading.** Ensure sub-sessions don't recursively
   load this extension (infinite/incorrect behavior). Resolve via a minimal ResourceLoader
   or disabled extension discovery. Confirm in the spike (§8 step 1).
6. **Abort/signal hygiene.** Thread `ctx.signal` into every sub-session and git/command call
   so Esc cancels promptly and disposes sessions.

## 10. Definition of done

- `/workflow <plan-path>` runs the full pipeline over a multi-task plan on a clean repo.
- Deterministic gates (ruff/ty/pytest) loop back to the implementer with feedback in the
  same session; verdict gates enforce `submit_verdict` (retry-then-abort).
- Per-transition caps + global budget enforced; exhaustion escalates via `ctx.ui.select`.
- Retro notes accumulate and demonstrably steer later tasks.
- Live dashboard reflects state/task/loop/gate; milestone entries recorded in the transcript.
- Framework contains zero references to ruff/ty/pytest or specific agent names; all of that
  lives in `workflows/python.ts` + `agents/*.md`.
- Clean shutdown on Esc; dirty-tree precondition aborts with a clear message.
