---
task-id: <NN>
blocked-by:
  - <ID>-<slug> of blocking tasks within this plan
---

# <NN>: Task title

Description of the task's "commit-sized" change within the full plan, i.e. the
end-to-end behaviour this task makes work.

Where a decision governs this task, cite the design record rather than restating
the argument (`design.md §6.2`).

## Changes

List of files that should be created, updated or deleted to reach the task's goal,
along with a description of the changes. Code snippets can be added directly
if they reflect an important design decision reached with the user. Otherwise,
just describe the expected behaviour.

## Tests

List of tests to add or modify, with a description of what should be tested.

This list is the agreed test plan: an agent implementing the task writes these
without asking again, and checks in only to deviate from them.
