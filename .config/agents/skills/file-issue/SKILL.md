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

## Template

```markdown
---
title: A one-liner description of the problem, structured like a conventional commit.
severity: low|medium|high, for triage
---

More in-depth description, detailing where the problem is, what impact it might have.
If relevant, a reproduction path.
```
