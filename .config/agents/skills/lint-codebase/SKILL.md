---
name: lint-codebase
description: Lint the codebase after a plan was implemented.
disable-model-invocation: true
---

List the changes made to the codebase. Check that:

- In-code documentation is correct
- `README.md` and `ARCHITECTURE.md` are up-to-date
- Examples still compile/run

Produce a list of elements that are stale, and check with the user whether they
should be fixed right away or filed to `.agent-workspace/issues/` with
/file-issue.
