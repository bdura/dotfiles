---
name: to-plan
description: Turn a spec or the current conversation into an implementation plan.
disable-model-invocation: true
---

# To Plan

Break a spec or conversation into a complete implementation plan, i.e. a set of
individual tasks.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a
spec path, read its full body.

### 2. Check existing plans for conflict

Read `.agent-workspace/plans/index.md` and any plan it lists that touches the
same code. Say so before drafting if two plans would collide.

### 3. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the
current state of the code. Start with the architecture document, and scan
`.agent-workspace/wiki/index.md` for relevant entries.

Look for opportunities to prefactor the code to make the implementation easier.
"Make the change easy, then make the easy change."

### 4. Draft tasks

Break the work into individual tasks (roughly sized to fit in a commit).

<task-rules>

- Each task cuts a narrow but COMPLETE path through every layer (schema, API,
  tests)
- A completed task is demoable or verifiable on its own
- Each task is sized to fit in a single fresh context window
- Any prefactoring should be done first, in a blocking task

</task-rules>

Give each task its **blocking edges**: the other tasks that must complete before
it can start. A task with no blockers can start immediately.

When relevant, adding a collection of integration tests that check behavior for
the completed feature should be appended to the list of tasks.

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each task, show:

- **Title**: short descriptive name
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this task makes work

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct: does each task only depend on tickets that
  genuinely gate it?
- Should any tickets be merged or split further?

Iterate until the user approves the breakdown.

### 6. File the plan

Create `.agent-workspace/plans/<feature-slug>/` and write four kinds of file into
it. Each fact belongs in exactly one of them.

<document-roles>

- `index.md` — the plan itself: task list, definition of done, dependency graph.
  It is the **sole owner** of all three; nothing else restates them.
  See [template](references/plan-template.md).
- `design.md` — **why**. The decisions, argued, under numbered sections
  so task files can cite them (`design.md §6.2`). Written once as a record of the
  reasoning; it is not maintained afterwards, and it carries no task breakdown.
  Omit it when the plan rests on no decision worth arguing.
- `context.md` — **what an implementer must know**: background distilled from
  `design.md` with the argument stripped out. This is the file tasks are expected
  to read, so keep it short enough to be worth loading every time.
- `<NN>-<slug>.md` — one per task, numbered from `01` in dependency order
  (blockers first). See [template](references/task-template.md).

</document-roles>

Between the task file, `index.md` and `context.md`, an agent should be able to
implement a task perfectly without reading anything else.

Then add a line to `.agent-workspace/plans/index.md`:

```markdown
- [<feature-slug>](<feature-slug>/index.md) — **status.** What the plan does, how
  many tasks, and the spec it implements.
```
