---
summary: >
  Hub page for Git working practices — how repository state is managed day to
  day, including worktree layout, context switching, and branch topology.
sources:
  - .agent-workspace/sources/matklad-git-worktrees-per-activity.md
tags:
  - git
  - workflow
  - hub
---

# Git workflow

Practices for working with Git repositories: how to hold work in progress, how
to lay out checkouts, and how to shape branch topology for review.

## Pages

- [[committing-instead-of-stashing]] — the staging area and stash treated as
  misfeatures; context is switched by making a throwaway `.` commit and
  resetting it later.
- [[git-worktrees-per-activity]] — worktrees allocated to concurrent activities
  (`main`, `work`, `review`, `fuzz`, `scratch`) rather than to branches, with
  observer trees kept in detached HEAD.

## Sub-hubs

- [[stacked-branch-workflow]] — a third axis: chains of dependent branches, each
  reviewed separately, and the tooling decisions that follow. Drawn from
  [[git-spice]].

## The through-line

These two pages come from one source and depend on each other. Branch switching
is solved by cheap throwaway commits; that frees worktrees to solve a different
problem, namely running several activities at once. Reading either alone gives
half the picture.

The source's own framing is a reaction against the common advice that worktrees
replace branches — a model its author tried and dropped.[^src]

Both pages also take a position on the staging area that stacking tools do not
share — see the taste difference recorded on [[stacked-branch-workflow]].

[^src]: [How I Use Git Worktrees](../sources/matklad-git-worktrees-per-activity.md),
    matklad, 2024-07-25.
