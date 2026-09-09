---
summary: >
  Whether the atomic reviewable unit is a commit or a branch. The commit model
  is closer to Git's philosophy; the branch model preserves the distinction
  between original work and review-feedback fixes.
sources:
  - git-spice @ 8b1262c3, doc/src/resources/faq.md
  - git-spice @ 8b1262c3, doc/src/guide/limits.md
tags:
  - review
  - git
  - design-decision
  - concept
---

# Unit of review: commit or branch

Every stacking tool must answer one question first: what is the atomic unit of
review? The answer splits the entire tool ecosystem in two.

- **Commit as the unit** — Gerrit, Phabricator, Jujutsu. One commit, one review.
  Amending is the natural edit.
- **Branch as the unit** — GitHub-style pull requests, and [[git-spice]]. One
  branch, one review; a branch may hold many commits.

## The argument for the branch

[[git-spice]] chooses the branch, and the FAQ makes the case better than most:[^faq]

> "there are two options: each commit is an atomic unit of work, or each branch
> is. While the former might be more in line with Git's original philosophy, the
> latter is more practical for most teams… With a PR per commit, when a PR gets
> review feedback, you must amend that commit with fixes and force-push. This is
> inconvenient for PR reviewers as there's no distinction between the original
> changes and those addressing feedback. However, with a PR per branch, you can
> keep the original changes separate from follow-up fixes, even if the branch is
> force-pushed."

The load-bearing observation is about **review ergonomics, not history
aesthetics**. A reviewer's question is "what changed since I last looked?" Under
the commit model the answer is destroyed by the very act of responding: the fix
is folded into the commit under review, and the force-push leaves the reviewer
diffing two versions of a single artifact. Under the branch model the fix is a
new commit — additive, visible, reviewable on its own.

Note this is not an argument that commits are the wrong unit *in principle*. The
FAQ concedes the commit model "might be more in line with Git's original
philosophy." It is an argument that the commit model shifts a cost onto the
reviewer, who did not choose it.

## The compensation

The obvious objection to branch-as-unit is that trunk history becomes a mess of
"fix review comment" commits. The answer:

> "with squash-merges, you can still get a clean history consisting of atomic,
> revertible commits on the trunk branch."[^faq]

So the two models are reconciled by *when* atomicity is enforced: the commit
model demands it during review, the branch model defers it to merge time. You get
one atomic commit per unit of work on trunk either way — the difference is
whether the mess is visible to reviewers or discarded at the boundary.

This is a clean example of a general move: **allow untidiness inside a boundary
and normalise at the exit**, rather than demanding tidiness throughout.

## The bill for that compensation

Squash-merging is not free. It replaces the branch's commits with a new commit
having a different hash, which strands every branch stacked above it. That
consequence is large enough to have its own page:
[[squash-merge-breaks-stacks]].

So the decision chain is worth seeing whole:

```raw
branch is the unit of review
  -> trunk history needs cleaning at merge time
    -> squash-merge
      -> hashes change, upstack is stranded
        -> restack machinery, repo sync, the merge experiment
```

A large part of git-spice's surface area exists to pay for a choice made about
review ergonomics.

## What the choice forecloses

The commit-as-changeset model, and with it the tools built on it. Someone who
wants `jj`-style per-commit review will not find it here — the branch is
structural in the data model, not a default. Conversely, the choice is what lets
git-spice work against unmodified GitHub-family forges at all: their review
primitive *is* the branch-to-branch diff. Choosing the commit as the unit would
have required a forge that agrees, which is why the commit-model tools ship their
own server.

## Related

- [[stacked-changes]] — the practice this decision sits inside
- [[squash-merge-breaks-stacks]] — the cost
- [[git-spice]]
- [[stacked-branch-workflow]] — hub

[^faq]: [FAQ — why not one CR per commit](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/faq.md), `doc/src/resources/faq.md`.
