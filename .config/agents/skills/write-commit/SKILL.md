---
name: write-commit
description: Write a git commit message. ALWAYS use when committing.
---

# Commit messages

Subject line only, conventional-commit style, unless the body earns its place.

A body is warranted when the *why* is not recoverable from the diff:
a non-obvious constraint, an alternative that was considered and rejected,
a bug the change prevents, a decision the user made that the code cannot show.

A body is not warranted for restating what the diff already shows, listing the
files touched, explaining a change the user just asked for, or narrating the
process that produced it.

When in doubt, no body. A one-line commit is the default, not the exception.

## Subject lines

- Conventional commit prefix, lowercase, imperative mood
- Say what changes, not what you did: `fix: anchor workspace paths`, not
  `fixed the paths in the skills`
- Scope it only when the scope is not obvious from the prefix

## Example

```gitcommit
fix: anchor workspace path

Note: committed by AI.
```
