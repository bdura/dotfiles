---
summary: >
  Hub page for Git working practices — how repository state is managed day to
  day, including worktree layout and context switching.
sources:
  - .agent-workspace/sources/matklad-git-worktrees-per-activity.md
tags:
  - git
  - workflow
  - hub
---

# Git workflow

Practices for working with Git repositories: how to hold work in progress, and
how to lay out checkouts.

## Pages

- [[committing-instead-of-stashing]] — the staging area and stash treated as
  misfeatures; context is switched by making a throwaway `.` commit and
  resetting it later.
- [[git-worktrees-per-activity]] — worktrees allocated to concurrent activities
  (`main`, `work`, `review`, `fuzz`, `scratch`) rather than to branches, with
  observer trees kept in detached HEAD.

## The through-line

These two pages come from one source and depend on each other. Branch switching
is solved by cheap throwaway commits; that frees worktrees to solve a different
problem, namely running several activities at once. Reading either alone gives
half the picture.

The source's own framing is a reaction against the common advice that worktrees
replace branches — a model its author tried and dropped.[^src]

[^src]: [How I Use Git Worktrees](../sources/matklad-git-worktrees-per-activity.md),
    matklad, 2024-07-25.
