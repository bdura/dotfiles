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
a spec path, read its full body and comments.

### 2. Check existing plans for conflict

Explore the existing plans in the workspace.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current
state of the code. Start with the architecture document, and scan the agent
workspace's wiki for relevant entries.

Look for opportunities to prefactor the code to make the implementation easier.
"Make the change easy, then make the easy change."

### 3. Draft tasks

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

### 4. Quiz the user

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

### 5. File the plan

Add the full implementation plan to the agent workspace:

- Create a `plans/<feature-slug>/` directory
- Add a plan overview under `plans/<feature-slug>/overview.md`.
  See [template](references/plan-template.md).
- Add a plan context under `plans/<feature-slug>/context.md`. It should contain
  anything in the repo, wiki, or anywhere else that's relevant to build the feature.
  An agent should be able to perfectly implement a task based on its description,
  the plan overview and this document alone.
- Write one file per task under `plans/<feature-slug>/<NN>-<slug>.md`,
  numbered from `01` in dependency order (blockers first). See
  [template](references/task-template.md).

Update `plans/index.md` with the new plan.
