---
summary: >
  Treating the staging area and the stash as misfeatures, and switching context
  by making a throwaway commit instead: `git add . && git commit -m.`, then
  `git reset HEAD~` on return.
sources:
  - .agent-workspace/sources/matklad-git-worktrees-per-activity.md
tags:
  - git
  - workflow
---

# Committing instead of stashing

The obstacle to switching branches mid-task is that Git cannot save your context
and restore it later. You have a branch, a commit, working-tree changes, some
staged and some not. Git's suggested answer is the stash — which the source
calls awkward: it is too easy to get lost with several stashes live at once, and
then apply one on top of the wrong branch.[^src]

The conclusion drawn is blunt: **the staging area and the stash are just bad
features, and life is easier if you avoid them.**[^src] Instead, commit whatever
you have and deal with it later.

## The pattern

Set the work aside:

```sh
git add .
git commit -m.
git switch another-branch
```

Pick it back up:

```sh
git switch -

# Undo the last commit, but keep its changes in the working tree
git reset HEAD~
```

The commit message is literally `.` — a marker that this is not real history.

## Two refinements

The commit-all step is wrapped in a `ggc` utility that does "commit all with a
trivial message" **atomically**.[^src] The source does not spell out what
atomicity buys here; the plain reading is that the add and the commit must not
be separable, so no half-applied state can be left behind. *Needs verification —
the implementation of `ggc` is not given in the source.*

The `reset HEAD~` is not automatic. The author often just keeps hacking with a
`.` sitting in the log, and amends that commit once satisfied with a subset of
the changes.[^src] The junk commit is a working surface, not only a parking
spot.

## Why this matters for worktrees

This pattern is what makes [[git-worktrees-per-activity]] coherent. Once
switching branches is cheap and safe, worktrees are freed from that job and can
be allocated to concurrency instead. The source is explicit that if you are
happily using worktrees as a branching replacement there is no need to change
anything — but the workflow described there depends on branch switching already
being a solved problem.[^src]

## Related

- [[git-worktrees-per-activity]]
- [[git-workflow]] — hub

[^src]: [How I Use Git Worktrees](../sources/matklad-git-worktrees-per-activity.md),
    matklad, 2024-07-25.
