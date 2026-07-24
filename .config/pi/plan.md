# Gated multi-agent workflow — implementation plan

## Context

We want a pi extension that runs a **deterministically-gated** multi-agent
implementation workflow: an *implementer* does the work, a *validator*
checks it and loops back on failure, and a final *conformity reviewer*
checks the result against the original plan. Crucially, the transitions
between agents are decided by **code**, not by an LLM — each gate agent
emits a machine-readable verdict and the engine branches on it.

This builds directly on the existing `examples/extensions/subagent/`
example, which already proves out spawning isolated child `pi` processes,
parsing their JSONL, tracking usage, streaming, and aborting. We reuse
those primitives and add the two things it lacks: **code-driven control
flow with loops** and a **deterministic verdict gate**.

The user's operating model: they set up their own branch/worktree and
write the plan by hand, then launch the workflow on the current CWD. The
engine never automates branch/worktree changes.

## Design decisions (resolved)

| Area | Decision |
|------|----------|
| Form | Extension-tool (not an SDK script) |
| Structure | Reusable **engine** (run-node / gate / loop primitives) + a **hardcoded pipeline instance** on top; scaffold allows other topologies later |
| Gate mechanism | Strict `submit_verdict` tool injected into the child via `-e`, returning `terminate: true`; engine reads the tool-call arguments from the child's JSONL. Missing verdict → `fail` (never a silent pass) |
| Plan input | Existing **file path**, caller-owned (`/gated-implement <planPath>`) |
| Ground truth | Working tree + **engine-computed `git diff`** injected into gates as text; implementer's summary is a hint only |
| Isolation | **Parent CWD**. Engine records a baseline ref (`git rev-parse HEAD`), asserts it's a git repo, computes `git diff <baseline>` (excluding `planPath`). No git automation |
| Preflight | Assert git repo + record baseline; check `git status --porcelain` (if dirty, **prompt via `ctx.ui`** soft gate — dirty is expected on relaunch); **verify every configured check command resolves, hard-abort with a setup message if any is missing** |
| Gate tools | `read, grep, ls, submit_verdict` — **no bash**, so a gate cannot mutate files |
| Deterministic check gate | After the implementer, **before** the agentic validator: run configured linters/type-checkers/tests (e.g. ruff, ty, pytest) via core `execCommand`. Any failure → **skip the agentic validator**, feed the failing check's raw output back to the implementer. Exit-code based, zero interpretation |
| Check config | Ordered `checks` list in `.pi/gated-workflow.json` (`[{name, command, args, timeout?}]`); auto-detected ecosystem preset as fallback (pyproject.toml → ruff/ty/pytest; package.json → biome/tsc/vitest). Explicit config wins |
| Check ordering | **Staged fail-fast** in listed order (fast→slow / prerequisite→dependent). Stop at the first failing check; send only that stage's output. Don't run pytest when ty fails |
| Check budget | Separate **`MAX_CHECK_FIX = 5`**, independent of `MAX_FIX`. Cheap objective fixes get more attempts and don't starve validation. Exhaustion → terminal-fail with the last check output |
| Control flow | Nested loops. Inner: implement → **checks (own budget)** → validate ⇄ implement (`MAX_FIX = 3`). Outer: review → re-enter (`MAX_REVIEW = 2`). Failed review re-enters **implement → re-checks → re-validate → re-review** |
| Verdict schema | `{ verdict: 'pass'\|'fail'\|'blocked', feedback?: string }` (required unless pass). `blocked` = not implementer-fixable → short-circuit to terminal-fail. Feedback is freeform markdown; a **render-layer parser** to structure it is a later phase |
| On failure | Leave tree as-is (never auto-revert); return fail + accumulated feedback history + baseline ref + diff summary + iteration counts |
| Relaunch | **Stateless** fresh run over the current tree + edited plan + optional `notes` arg. No persistence layer — disk + plan file are the state |
| Role defs | Bundled markdown in `roles/` next to the extension (frontmatter: `model`, `tools`; body: prompt), loaded by relative path |
| Models | implementer → strong (opus/sonnet); validator → sonnet; reviewer → sonnet (set in role frontmatter) |
| Trigger | `/gated-implement <planPath> [notes]` primary + `run_gated_workflow({planPath, notes?})` tool; **one shared engine function** |
| Node runner | Copy + adapt a trimmed `runNode()` from `subagent/index.ts` (single sequential agent; adds `-e` injection, diff injection, verdict extraction). No cross-example coupling |
| Rendering | Engine emits `onProgress(state)`; tool path adapts to `renderResult`/`onUpdate`, command path adapts to `appendEntry` + `registerEntryRenderer`. Live pipeline step-list with per-node status, iteration markers (`fix 2/3`, `review 1/2`), streamed tool calls, verdicts, per-node + total usage |
| Abort | Reuse the example's `SIGTERM` → `SIGKILL`-after-5s child propagation |

## Control flow (the state machine)

```text
preflight: load checks (config file or preset)
           assert git repo; baseline = git rev-parse HEAD
           git status dirty? -> ctx.ui prompt (proceed / abort)
           every check command resolvable? else -> ABORT(setup message)

implement(task = plan + optional notes)          # roles/implementer.md

outer (reviewIter = 1..MAX_REVIEW):
    inner:
        # --- deterministic check gate (own budget) ---
        checkFix = 0
        loop:
            fail = run_checks_staged()            # execCommand each, stop at first non-zero
            if fail is None: break                # all checks pass -> proceed to validator
            checkFix += 1
            if checkFix > MAX_CHECK_FIX: return FAIL(checks exhausted, fail.output)
            implement(task = "fix these check failures:\n" + fail.output)   # SKIP validator

        # --- agentic validation gate ---
        diff = git diff <baseline> (exclude planPath, truncate ~50KB)
        v = validate(plan, diff)                  # roles/validator.md + submit_verdict
        if v.verdict == 'pass':    break inner
        if v.verdict == 'blocked': return FAIL(blocked, v.feedback)
        if validatorFix++ >= MAX_FIX: return FAIL(fix budget exhausted, feedbackHistory)
        implement(task = "fix per feedback: " + v.feedback)   # back to check gate

    # --- conformity review ---
    diff = git diff <baseline> (...)
    r = review(plan, diff)                        # roles/reviewer.md + submit_verdict
    if r.verdict == 'pass':    return OK(diff summary, usage)
    if r.verdict == 'blocked': return FAIL(blocked, r.feedback)
    implement(task = "address conformity findings: " + r.feedback)   # re-enter outer
else: return FAIL(review budget exhausted, feedbackHistory)
```

Note: after any check-fix or validator-fix loops back to the implementer, the
next inner pass re-runs the **check gate first** — so the agentic validator
only ever sees code that lint/type/test-passes, and the conformity reviewer
only ever sees code that has passed both gates.

Notes:

- Verdict guarantees the branch is deterministic once emitted; `terminate: true`
  guarantees the gate's tool call is the child's last event (see below).
- Gates must call `submit_verdict` **alone** in their final message —
  `shouldTerminateToolBatch` only terminates a batch if *every* call in it
  has `terminate: true`. Enforced in the gate role prompts.

## Why `terminate: true` (the gate primitive)

`agent/src/agent-loop.ts:216` sets `hasMoreToolCalls = !executedToolBatch.terminate`;
`shouldTerminateToolBatch` (`:582`) terminates the batch only when every finalized
call returns `terminate: true`. So a `submit_verdict` tool that returns
`{ terminate: true }` makes the child agent **end on that call** with no
trailing free-text turn. The verdict is therefore the last, typed,
pre-validated event in the child's JSONL — no prose parsing, no ambiguity.

## Files (new)

```text
examples/extensions/gated-workflow/
  index.ts          # registers the tool + command; wires rendering adapters
  engine.ts         # runNode() + the state machine (engine.run(planPath, notes, {onProgress}))
  verdict-tool.ts   # submit_verdict tool, loaded into gate children via -e
  checks.ts         # load config/preset, resolve commands (preflight), runChecksStaged() via execCommand
  git.ts            # baseline ref, git-repo assert, computeDiff(baseline, excludePaths), status --porcelain
  render.ts         # onProgress state -> TUI (formatToolCall/usage adapted from subagent)
  roles/
    implementer.md  # model + tools: read,grep,ls,edit,write,bash ; prompt
    validator.md    # model + tools: read,grep,ls,submit_verdict ; verdict-alone protocol
    reviewer.md     # model + tools: read,grep,ls,submit_verdict ; conformity-vs-plan protocol
  README.md
```

Reference existing code to reuse/adapt:

- `examples/extensions/subagent/index.ts` — `runSingleAgent` (→ `runNode`),
  `getPiInvocation`, JSONL parsing, usage aggregation, `formatToolCall`,
  `formatUsageStats`, `renderResult`, abort handling, `truncateParallelOutput`
  (→ diff truncation), `writePromptToTempFile`.
- `examples/extensions/subagent/agents.ts` — frontmatter loading pattern for `roles/*.md`.
- `examples/extensions/structured-output.ts` — `terminate: true` + `details` pattern for `verdict-tool.ts`.
- `examples/extensions/entry-renderer.ts` — `appendEntry` / `registerEntryRenderer` for the command render path.
- `src/core/exec.ts` — **`execCommand(command, args, cwd, { signal, timeout })`** →
  `{ stdout, stderr, code, killed }` for the deterministic check gate
  (abort-aware, timeout-aware, `shell: false`; distinguish ENOENT spawn-error
  from a real non-zero exit at preflight).
- CLI flags already confirmed present (`src/cli/args.ts`): `--mode json`, `-p`,
  `--no-session`, `--model`, `--tools`, `--append-system-prompt`, `--extension/-e`.

## Verification (end-to-end)

1. **Happy path**: on a clean branch, write a small plan (e.g. "add a
   `formatBytes` helper to `utils.ts` with tests"). Run
   `./pi-test.sh --extension examples/extensions/gated-workflow/index.ts`,
   then `/gated-implement tmp/plan.md`. Expect: implement → validate(pass)
   → review(pass) → OK, with a real diff on disk.
2. **Check gate**: with a `.pi/gated-workflow.json` listing ruff/ty/pytest on a
   Python project, have the implementer produce code that lints/types clean but
   fails a test; confirm the check gate catches it, the **agentic validator is
   skipped**, raw pytest output is fed back, and it re-runs the check gate on the
   next pass. Also confirm staged fail-fast (introduce a ruff error → only ruff
   runs; fix it → ty runs; etc.).
3. **Check budget**: force a perpetual check failure; confirm exhaustion at
   `MAX_CHECK_FIX` → terminal-fail with the last check output, distinct from the
   validator budget.
4. **Missing check preflight**: point a check at a non-existent command; confirm
   the run **aborts before implementing** with a clear setup message (no
   implementer iterations wasted).
5. **Fix loop**: use a plan whose obvious first implementation is subtly
   wrong *but check-clean*; confirm validator returns `fail`, the implementer
   receives the feedback verbatim, and a second attempt passes (`fix 2/3` shown).
6. **Conformity re-entry**: plan that says X; nudge the implementer (via a
   misleading role tweak or notes) to drift to Y; confirm the reviewer
   `fail` re-enters implement → re-validate → re-review.
7. **Budgets**: force perpetual `fail` (e.g. impossible plan); confirm inner
   exhaustion at `MAX_FIX`, outer at `MAX_REVIEW`, terminal-fail report with
   full feedback history + baseline ref, tree left as-is.
8. **Blocked**: plan with a self-contradiction; confirm a `blocked` verdict
   short-circuits to terminal-fail without burning the budget.
9. **Preflight**: run with a dirty tree; confirm the `ctx.ui` prompt appears
   and abort/proceed both behave.
10. **Determinism of the gate**: kill a gate child before it emits / point it
    at a bad model; confirm "no verdict emitted" → `fail`, never a silent pass.
11. **Both entry points**: confirm `/gated-implement` and the
    `run_gated_workflow` tool drive the same engine and render correctly.
12. `npm run check` (biome + tsgo) passes on the new files.

## Later phases (explicitly deferred)

- Render-layer parser: freeform `feedback` → `{file, line, severity, detail}`
  for richer display. Does **not** touch the gate contract or control flow.
- Additional pipeline topologies on the same engine scaffold.
- Optional planner/scout prepend stage.
- Persisted resume (`--resume`) if stateless relaunch proves insufficient.
