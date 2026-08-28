---
name: implement
description: Implement a piece of work based on an implementation plan.
disable-model-invocation: true
---

Implement the work described by the user in a task. That task is part of a plan,
named `<plan-slug>`. Read its overview (at `plans/<plan-slug>/overview.md`)
and context (at `plans/<plan-slug>/context.md`) first.

Use /tdd where possible, at pre-agreed test locations.

Run typechecking regularly, and the full test suite once at the end.

Commit your work to the current branch, using a one-liner conventional commit.
