---
summary: >
  Hub for the stacked-branch way of working — shaping a chain of dependent
  branches and getting each reviewed separately — and the design decisions
  tooling for it has to make.
sources:
  - git-spice @ 8b1262c3, doc/src/**
tags:
  - git
  - stacking
  - review
  - hub
---

# Stacked-branch workflow

A third axis of Git practice alongside the two under [[git-workflow]]. Those ask
*where do I park work in progress* and *how do I lay out checkouts*. This one
asks: **how do I shape a series of dependent branches, and get each of them
reviewed on its own?**

The material here comes from reading [[git-spice]]'s documentation, but most of
the pages are about the general problem rather than that one tool.

## The practice

- [[stacked-changes]] — what stacking is, why (unblock yourself; small diffs get
  real reviews), and the vocabulary: trunk, stack, upstack, downstack, sibling,
  restacking, tracking.
- [[forge-and-change-request]] — "forge" as the interchangeable category of
  hosting platforms, "change request" as the forge-neutral noun, and where the
  platforms stop being interchangeable.

## The decisions any such tool must make

- [[unit-of-review-commit-vs-branch]] — commit or branch as the atomic
  reviewable unit. The choice that splits the whole tool ecosystem in two.
- [[squash-merge-breaks-stacks]] — the forge-side fact that content-preserving,
  identity-destroying merges strand everything stacked above. Most of the
  tooling surface exists to pay for this.
- [[state-in-a-repository-ref]] — where to keep metadata Git will not keep for
  you, and what a Git ref buys over a dotfile.
- [[metadata-update-vs-content-replay]] — retarget now, rebase on request; keep
  the failure-prone half out of the habitual command.
- [[incrementally-adoptable-tooling]] — build it so nothing is required, and pay
  for that in continuous reconciliation.
- [[subprocess-the-reference-implementation]] — drive the real `git` rather than
  a library, and inherit both its correctness and its contention.

## The through-line

The pages are not independent. There is a single chain of consequence running
through them, and it is the most useful thing to carry away:

```raw
review is per branch, not per commit
  -> trunk history must be cleaned at merge time -> squash-merge
    -> merging rewrites hashes -> the upstack is stranded
      -> you need a recorded branch graph to know what to repair
        -> and a way to repair it that does not ambush you with conflicts
```

Read top to bottom, that is [[unit-of-review-commit-vs-branch]] →
[[squash-merge-breaks-stacks]] → [[state-in-a-repository-ref]] →
[[metadata-update-vs-content-replay]]. A decision about *review ergonomics*
propagates all the way down into the data model.

## A difference in taste worth naming

The existing [[committing-instead-of-stashing]] page adopts matklad's position
that "the staging area and the stash are just bad features."

git-spice's default flow leans *on* the staging area: `gs branch create` creates
the branch, **commits the staged files**, and tracks it — and with nothing
staged it creates an empty commit. `spice.branchCreate.commit = false` opts out.

The two sources agree that cheap, throwaway commits are fine. They disagree on
whether the index is a useful surface. Not a factual conflict — a difference in
taste, recorded here so a reader arriving from one page is not surprised by the
other.

## Related

- [[git-workflow]] — parent hub
- [[git-spice]] — the explored project

