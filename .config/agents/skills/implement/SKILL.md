---
name: implement
description: Implement a piece of work based on an implementation plan.
disable-model-invocation: true
user-invocable: true
---

# Implement a task

Implement a single task from the plan named `<plan-slug>`. Read, in order:

- the task file, `.agent-workspace/plans/<plan-slug>/<NN>-<task-slug>.md`
- the plan, `.agent-workspace/plans/<plan-slug>/index.md`
- the shared context, `.agent-workspace/plans/<plan-slug>/context.md`

If the user names a task without its number, find it in the plan. If any of its
blockers is still unticked, say so before starting.

Use /tdd where possible. The task file's `## Tests` section is the agreed test list:
write those tests without re-confirming, and check with the user only if you need
to deviate from them.

Run typechecking regularly, and the full test suite once at the end.

## Finishing

The workspace is a git worktree on the `agent-workspace` branch, so it commits
separately from the code. Once the task is done:

1. Commit the code to the current branch, with a one-liner conventional commit.

If /implement-plan dispatched you, stop here and report: what you changed,
the test command you ran, and the tail of its output. The runner verifies that
evidence before it records anything, so leave the workspace alone.

Otherwise, finish the bookkeeping yourself:

2. Tick the task in `.agent-workspace/plans/<plan-slug>/index.md`.
3. Commit the workspace: `git -C .agent-workspace commit`.

Leave the definition-of-done boxes alone unless you ran what they ask for and
watched it pass.
