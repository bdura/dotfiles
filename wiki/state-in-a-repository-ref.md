---
summary: >
  Keeping a tool's own metadata in a Git ref inside the repository rather than
  in a dotfile or an external database: it becomes versioned, auditable,
  repo-scoped and worktree-shared for free — but it does not travel.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/internals.md
  - git-spice @ 8b1262c3, doc/src/index.md
tags:
  - git
  - design-decision
  - state
  - concept
---

# State in a repository ref

[[git-spice]] must remember which branch is based on which — Git does not record
it (see the tracking section of [[stacked-changes]]). The choice of *where* to
put that memory is more consequential than it looks.

## The decision

All tracking metadata lives in a local Git ref, `refs/spice/data`, holding JSON
blobs: `repo`, `templates`, `rebase-continue`, `branches/<name>`,
`prepared/<name>`.[^internals]

The obvious alternatives were a file in `.git/`, or a database in the user's home
directory keyed by repository path.

## What the ref buys

**Offline-first, which is the stated motivation.** "All state is stored locally
in your Git repository. A network connection is not required, except when pushing
or pulling."[^index] Local stacking needs no authentication at all.[^auth]

**Versioned history, for free.** Because a ref is a commit chain, every mutation
is a commit. The docs note that "git-spice operations that manipulate this
information will usually include what prompted the change," so you can read the
audit trail with:

```sh
git log --patch refs/spice/data
```

This is the part worth stealing. A dotfile gives you current state; a ref gives
you *how the state got that way*, using machinery you already ship. For a tool
whose failure mode is "my stack graph is wrong and I don't know why", an audit
log is close to essential — and it cost nothing to build.

**Correct scoping, for free.** A ref is per-repository by construction, so no
path-keyed lookup and no stale entries for deleted clones. It is also shared
across worktrees of the same repository, which matters given how worktree-aware
the tool is — see [[git-worktrees-per-activity]].

**Nothing to clean up.** Delete the repository, the metadata goes with it.

## What it costs

**The graph does not travel.** The ref is local and not pushed, so the stack
topology does not reach another machine or another person. A colleague picking up
your branches must reconstruct it with `gs downstack track`.

*The docs never state this limitation directly.* The inference is safe, though,
because the import instructions in the change-request guide are the practical
acknowledgement of it: adopting existing CRs means checking out, tracking, and
resubmitting. **Inferred.**

Whether this is a flaw depends on your view: it is also what makes the tool
zero-configuration for collaborators, who need not have it installed at all. A
pushed ref would make the stack shared state, and shared state needs conflict
resolution.

**A custom format inside an opaque object.** The data is not human-editable in
place; you inspect it with `git cat-file`-style plumbing. Hence the stability
warning below.

## The instability warning, and the recipe that ignores it

`guide/internals.md` is blunt: "Do not rely on internal details to remain stable.
These may change at any time." It opens by telling most readers not to bother:
"Most users do not need to read this. It is presented here for the curious, and
in the interest of transparency."[^internals]

And yet `resources/recipes.md` publishes a `post-checkout` hook that reads
`refs/spice/data:branches/<name>` directly, justified on the grounds that the
supported command "will be slower here", and carrying its own caveat: "Warning:
This may break if git-spice's internal storage format changes."[^recipes]

So the officially recommended recipe does the thing the internals page forbids.
The docs are aware and label it, which is honest, but the real signal is a
**missing supported query**: there is no fast `gs`-level "is this branch
tracked?" check, so the escape hatch is to read private state. When your own
recipes bypass your API, the API has a hole.

## The general pattern

**Store tool metadata in the versioned substrate the tool already operates on.**
Applicable well beyond Git: the win is that scoping, lifecycle, history and
cleanup all come from the host system rather than being reimplemented. The
questions to ask before adopting it are the two above — does the metadata need to
travel, and can you commit to a stable format, or will you be publishing a
"don't depend on this" warning that your own users then depend on anyway.

## Related

- [[stacked-changes]] — what tracking is, and why the state is needed
- [[metadata-update-vs-content-replay]] — this state being edited independently
  of the working tree
- [[incrementally-adoptable-tooling]] — the drift this state can fall into
- [[git-spice]]

[^internals]: [Internals](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/internals.md), `doc/src/guide/internals.md`.
[^index]: [Home](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/index.md), `doc/src/index.md`.
[^auth]: [Authentication](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/setup/auth.md), `doc/src/setup/auth.md`.
[^recipes]: [Recipes](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/recipes.md), `doc/src/resources/recipes.md`.
