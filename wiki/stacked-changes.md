---
summary: >
  The practice of splitting work into a chain of dependent branches, each
  reviewed separately, and the vocabulary it needs: trunk, stack, upstack,
  downstack, sibling, restacking, tracking.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/concepts.md
  - git-spice @ 8b1262c3, doc/src/resources/faq.md
tags:
  - git
  - stacking
  - concept
  - workflow
---

# Stacked changes

**Stacking** is splitting a body of work into several dependent branches, each
one based on the last, and submitting each for review separately instead of
shipping one large change. The general practice has its own site,
<https://www.stacking.dev/>; this page uses [[git-spice]]'s definitions because
they are unusually precise.

## Why

Two reasons, both from the FAQ:[^faq]

- **Unblock yourself.** Work on the next branch while the previous one waits in
  review, instead of idling on a review round-trip.
- **Be kinder to your team.** "A 100 line PR gets a more meaningful review than a
  1000 line PR."

The cost is bookkeeping: every branch must be rebased when anything below it
changes, and every review must be retargeted when anything below it merges. That
bookkeeping is the entire reason tools like git-spice exist.

## Vocabulary

Quoted or closely paraphrased from `guide/concepts.md`.[^concepts]

- **Branch** — a regular Git branch. A branch may have a **base**: "the branch
  they were created from."
- **Trunk** — "The default branch of a repository… Trunk is the only branch that
  does not have a base branch." This is load-bearing: base-ness is total except
  at trunk, so the whole tracked set is a **forest rooted at trunk**.
- **Stack** — "a collection of branches stacked on top of each other in a way
  that each branch except the trunk has a base branch." Crucially: "A branch can
  have multiple branches stacked on top of it." **A stack is a tree, not a
  list** — the word misleads.
- **Downstack** — "the branches below the current branch, all the way to, but
  not including, the trunk branch." A single path.
- **Upstack** — "the branches stacked on top of the current branch, those
  branches' upstacks, and so on until no more branches remain." A transitive
  closure.

  The asymmetry matters and is easy to miss: *downstack is a path, upstack is a
  subtree*. It explains why `gs downstack merge` makes sense as an ordered
  sequence while `gs upstack restack` is a fan-out.
- **Sibling** — "a branch that shares the same base branch."
- **Restacking** — "the process of rebasing the contents of a branch on top of
  its base branch, which it may have diverged from. This is done to keep the
  branch up-to-date with its base branch, and maintain a linear history."

## Tracking: the pivotal term

A stacking tool cannot infer the graph from Git alone, because Git does not
record which branch a branch was created from. So the relationship must be
stored somewhere:

> "git-spice learns about the relationships between branches by 'tracking' them
> in an internal data store."[^branch]

A branch is either **tracked** or **untracked**; untracked branches are
invisible to every stack operation. This single term is the hinge of the whole
design — it is what makes the tool's model additive rather than mandatory (see
[[incrementally-adoptable-tooling]]) and it is what needs somewhere to live (see
[[state-in-a-repository-ref]]).

*The docs define tracking in passing, on the branch-management page rather than
in the glossary — under-defined relative to its importance.*

## What stacking demands of the tooling

Each definition above implies an operation, and the reason each is hard:

| Because | You need | Difficulty |
| --- | --- | --- |
| bases diverge | restack | rebases conflict |
| upstack is a subtree | recursive restack | one conflict blocks a fan-out |
| CRs target branches, not trunk | retarget on merge | forge-side, needs network |
| squash-merge rewrites hashes | detect + restack everything above | see [[squash-merge-breaks-stacks]] |
| review is per branch | one CR per branch | see [[unit-of-review-commit-vs-branch]] |
| reviewers see no stack | synthesise one in a comment | forge UI has no such concept |

The last row is worth naming: forges have no notion of a stack, so git-spice
posts a **navigation comment** on each CR rendering the stack with a marker on
the current one, and keeps it updated. When the stack has only one CR the
comment is suppressed by default — don't add noise when there is nothing to
explain.

## Relation to plain Git

Git's own `rebase --update-refs` solves part of the restacking problem natively.
git-spice promises not to fight it: "If you run a git-spice restack operation, it
will automatically detect that the branches are already properly stacked, and
leave them as-is."[^faq] That promise forces restacking to be **idempotent and
no-op-detecting** rather than unconditional — a real implementation constraint
accepted to avoid an either/or.

## Related

- [[git-spice]] — the tool this vocabulary comes from
- [[forge-and-change-request]] — the remote half of the model
- [[stacked-branch-workflow]] — hub

[^concepts]: [Concepts](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/concepts.md), `doc/src/guide/concepts.md`.
[^faq]: [FAQ](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/faq.md), `doc/src/resources/faq.md`.
[^branch]: [Branch management](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/branch.md), `doc/src/guide/branch.md`.
