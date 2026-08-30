---
name: implement-plan
description: Implement an entire plan, running /implement on each task in turn.
disable-model-invocation: true
user-invocable: true
---

# Implement a plan

Carry a plan in `.agent-workspace/plans/<plan-slug>/` to completion, one task at
a time. Each task runs in a fresh subagent, because the tasks were sized to fit a
fresh context window and this orchestrator must stay thin enough to see the plan
through to the end.

If the user did not name a plan, list what is in `.agent-workspace/plans/index.md`
with each plan's progress, and ask which to run.

## Preflight

Read the plan's `index.md`, then the `blocked-by` frontmatter of every task file.

Honour the plan's `Target:` line: create the branch at the stated base if it does
not exist, check it out if it does. If the base has moved since the plan was
written, say so and ask before proceeding.

Refuse to start if either tree is dirty — the project's or the workspace's.
Say which one, and stop. Do not stash.

## The loop

Until no task is ready:

1. **Ready set.** The unticked tasks whose `blocked-by` are all ticked.
   If it is empty while tasks remain unticked, the rest of the plan is blocked:
   stop, and say what it is blocked on.

2. **Dispatch** the lowest-numbered ready task to a fresh general-purpose subagent.
   Tell it to run /implement on task `<NN>` of plan `<plan-slug>`, and to report
   back what it changed, the test command it ran, and the tail of that command's
   output.

3. **Verify** before recording anything that the report carries a test command
   and its output, not just an assurance. If that's not the case, halt.
   Do not tick, and do not dispatch anything else.

4. **Commit.** Commit the code to the target branch with a one-liner conventional
   commit.

5. **Record.** Tick the task in the plan's `index.md`, then commit the workspace
   with `git -C .agent-workspace commit`.

Halt on any subagent that reports failure, cannot get the bar green, or wants
to deviate from its task's agreed `## Tests`. Say which task stopped it, why,
and what remains. The user fixes it, then re-runs this skill: the tick marks are
the only state, so it resumes from where it stopped.

Report each task as it lands — one line, task and commit — rather than saving
everything for the end.

## When every task is ticked

Walk the definition of done item by item. Run what can be run, and tick only those.
Report the rest as unverified with the reason — never tick an item by inspection.

Then hand off to /lint-codebase.
