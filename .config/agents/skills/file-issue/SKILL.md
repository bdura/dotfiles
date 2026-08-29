---
name: file-issue
description: File an issue to the workspace. Use when an issue is detected in the code.
---

# Issue

The agent files issues that they spot while working on unrelated features.

Those can be:

- stale comment or documentation
- actual bugs or edge-cases
- missing tests
- possible performance problem

The issue lays out all the context needed to understand it. A separate agent with
no prior knowledge should be able to understand it from reading only.

## Filing

Write the issue to `.agent-workspace/issues/<slug>.md`, then add a line to
`.agent-workspace/issues/index.md`:

```markdown
- [<slug>](<slug>.md) — **severity.** One line on what is wrong and why it
  matters.
```

The workspace is a git worktree on the `agent-workspace` branch: commit the issue
with `git -C .agent-workspace commit`, separately from any code.

An issue is closed by deleting its file and its index line once the fix lands —
see /fix-issue. There is no resolved state to set.

## Template

```markdown
---
title: A one-liner description of the problem, structured like a conventional commit.
severity: low|medium|high, for triage
---

More in-depth description, detailing where the problem is, what impact it might have.
If relevant, a reproduction path.
```
