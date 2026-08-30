---
name: lint-codebase
description: Lint the codebase after a plan was implemented.
user-invocable: true
---

# Lint the codebase

List the changes made to the codebase. Check that:

- In-code documentation is correct
- `README.md` and `ARCHITECTURE.md` are up-to-date
- Examples still compile/run

Produce a list of elements that are stale, and check with the user whether they
should be fixed right away or filed as issues with /file-issue.
