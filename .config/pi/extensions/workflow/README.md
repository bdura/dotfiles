# Workflow — deterministic multi-agent implementation

A Pi extension that runs a **state-machine-driven** multi-agent workflow over a
pre-written implementation plan. Unlike model-driven delegation, the *extension*
deterministically drives transitions between agents, gating each step with either
deterministic checks (lint/type/test) or agent-led structured verdicts.

See [plan.md](./plan.md) for the full design and rationale.

## Usage

```
/workflow <path-to-plan.md>
```

Preconditions:
- You are inside a **git repo** with a **clean working tree** (the run diffs against
  the starting `HEAD`; it never switches branches or commits for you).
- The plan file contains an ordered task list, using either convention:
  - `## Task: <title>` sections, or
  - `- [ ] <title>` checklist items (indented lines below become the task body).

For each task the pipeline runs:

```
implement → ruff → ty → pytest → validate → review → retro → next task
```

- Any failing gate routes back to the **implementer** (same session, fix-forward) with
  the failure feedback as plaintext.
- `validate` / `review` are agent-led: the agent must call `submit_verdict`. If it
  doesn't after a couple of reprompts, the run aborts.
- `retro` updates docs and emits steering notes that are injected into later tasks.
- Per-transition loop caps + a global budget bound the run; on exhaustion you're asked
  to retry / abort / accept.
- Progress shows in a live widget; milestones are logged to the session transcript.

Abort by quitting Pi (the run is aborted on `session_shutdown`). v1 keeps no state and
is not resumable; partial changes remain in your working tree (`git diff` to inspect).

## Architecture

- `framework/` — domain-agnostic engine, sub-session runner, gate primitives,
  git/handoff helpers, plan parser, dashboard. Contains **no** tool or agent names.
- `workflows/python.ts` — the concrete graph: ruff/ty/pytest commands + validator/
  reviewer verdict schemas + loop caps.
- `agents/*.md` — role prompts with frontmatter (`name`, `model`, `tools`).

## Adapting to another project / language

Everything project-specific lives in the instantiation:

1. Edit the gate commands in `workflows/python.ts`
   (`RUFF_COMMAND`, `TY_COMMAND`, `PYTEST_COMMAND`) — or copy the file to a new
   `workflows/<lang>.ts` and adjust the state graph.
2. Tune verdict schemas, `maxLoops`, and `globalBudget` there.
3. Edit the agent prompts / models / tools in `agents/*.md`.

The framework does not need to change.

## Status

Framework modules, plan parsing, git/handoff helpers, block extraction, and graph
construction are smoke-tested. The live LLM sub-sessions (verdict `terminate: true`
capture, fix-forward loop) require provider auth and real model calls — run the
manual spike in `plan.md` §8 step 1 to validate them in your environment before first
production use.
