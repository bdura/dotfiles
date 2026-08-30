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
- No comment restates the code, replays the conversation that produced it,
  or logs a past implementation that git already records

Produce a list of elements that are stale, and check with the user whether they
should be fixed right away or filed as issues with /file-issue.

If the residue is spread across the whole diff rather than a few spots,
run /deslop instead of fixing it line by line here.
