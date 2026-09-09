---
summary: >
  Squash-merging replaces a branch's commits with one new commit of a different
  hash, so every branch stacked above it is stranded and must be restacked. A
  forge-side fact, not a tool limitation, that shapes stacking tools heavily.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/limits.md
  - git-spice @ 8b1262c3, doc/src/guide/cr.md
tags:
  - git
  - forge
  - stacking
  - concept
---

# Squash-merge breaks stacks

A plain Git and forge fact, independent of any tool, and the single technical
constraint that most shapes [[git-spice]].

## The mechanism

When a change request is squash-merged, the forge does not apply the branch's
commits to trunk. It creates **one new commit with a different hash** containing
the same tree. The original commits never appear on trunk.

Now consider a stack `main -> A -> B`. `A` is squash-merged. Trunk gains commit
`A'`, whose content equals `A` but whose hash does not. `B` is still based on the
original `A` commits, which are now unreachable from trunk. So:

- `B`'s history contains commits that will never be on trunk.
- A diff of `B` against trunk shows `A`'s changes *again*, on top of `A'`.
- Rebasing `B` onto trunk replays `A`'s commits onto a trunk that already has
  their content — which is where conflicts come from, even though nothing
  actually disagrees.

The docs state it directly:

> the squash "replaces commits… with a single commit with a different hash…
> GitHub and GitLab do not yet know to reconcile this new commit with the upstack
> branches, even though the contents are the same."[^limits]

Note the last clause. The content is identical; only identity is lost. The
problem is entirely one of **commit identity, not of content**.

## Why it is unavoidable

The docs attribute the gap to the forges, not to themselves, and it is a fair
attribution: nothing in the squash-merge API tells the forge that other open CRs
were based on the commits it just discarded. There is a source `<!-- TODO -->` in
the docs noting an upstream issue that could alleviate it.

And squash-merging is not an incidental habit — it is the compensation that makes
branch-as-unit-of-review give clean trunk history. See
[[unit-of-review-commit-vs-branch]]. So a stacking tool cannot simply advise
against it.

## What it forces the tool to build

Essentially the whole synchronisation surface:

- **`gs repo sync`** — pull trunk, detect which CRs merged, delete their local
  branches, and retarget survivors onto the next available branch downstack or
  onto trunk.[^cr]
- **Restacking on request** — the retarget alone does not fix the content
  problem; the branches still need rebasing. Deliberately not done by default:
  see [[metadata-update-vs-content-replay]].
- **The stack-merge experiment** — merge bottom-up from the CLI, waiting for each
  CR to become ready and restacking above it before continuing, precisely
  because merging the bottom of a stack invalidates everything above it. Still
  experimental, and gated behind config.

For merges that are *not* done through a supported forge, the docs concede the
detection fails: `gs repo sync` catches merge commits and fast-forwards, but "For
branches that were merged by rebasing or squashing, you'll need to manually
delete merged branches."[^recipes] Squash-merge detection depends on asking the
forge, which is why this is the one place the offline-first design must go to the
network.

## The general shape

This is a recognisable class of problem: **an operation that preserves content
but destroys identity breaks everything downstream that referenced the identity.**
The same shape appears in rebased dependency branches, amended commits others
have pulled, and rewritten history in general. The remedy is always the same
kind: re-derive the dependents, and keep enough out-of-band metadata to know
which dependents existed. In git-spice's case that metadata lives in
[[state-in-a-repository-ref]].

## Related

- [[unit-of-review-commit-vs-branch]] — why squash-merge is being used at all
- [[metadata-update-vs-content-replay]] — how the repair is sequenced
- [[stacked-changes]]
- [[stacked-branch-workflow]] — hub

[^limits]: [Limitations](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/limits.md), `doc/src/guide/limits.md`.
[^cr]: [Change requests](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/cr.md), `doc/src/guide/cr.md`.
[^recipes]: [Recipes](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/recipes.md), `doc/src/resources/recipes.md`.
