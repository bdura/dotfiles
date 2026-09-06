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

Write what you would want to read cold: no comment that restates the code, no
changelog in the source, nothing that betrays this conversation. A comment earns
its place by saying *why*. /deslop cleans up after you — do not give it work.

## Finishing

Once the task is done, report: what you changed, the test command you ran,
and the tail of its output. Leave the workspace alone — do **not** commit code
or workspace.

The user (or /implement-plan if it dispatched you) is responsible for reviewing
the work and committing it. You can commit on the user's request.

Leave the definition-of-done boxes alone unless you ran what they ask for and
watched it pass.
