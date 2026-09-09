---
summary: >
  Separating a cheap graph edit that always succeeds from the expensive,
  conflict-prone replay of content that realises it — so the common command
  stays non-interactive and never drops the user into a rebase.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/cr.md
  - git-spice @ 8b1262c3, doc/src/cli/config.md
tags:
  - design-decision
  - concept
  - git
---

# Metadata update vs content replay

Operations in [[git-spice]] that change the shape of a stack — `gs repo sync`,
`gs branch delete`, `gs branch onto` — update the *recorded* base of the affected
branches but do **not** rebase their contents unless you ask.

## The two halves

| | Graph edit (retarget) | Content replay (restack) |
| --- | --- | --- |
| What it touches | the metadata in [[state-in-a-repository-ref]] | the actual commits |
| Cost | trivial | a rebase per branch |
| Can it fail? | no | yes — conflicts |
| Interactive? | never | possibly, for a long time |

Bundling them means the cheap, reliable half inherits the failure modes of the
expensive one.

## The evidence

`gs repo sync` "will retarget those surviving branches onto the next available
branch downstack, or onto trunk. It does not rebase them by default, so those
branches may need an explicit `gs branch restack`."[^cr]

The same for `gs branch delete` — "Branches upstack from deleted branches are not
rebased by default" — and for `gs branch onto`, where branches are "retargeted in
git-spice state and can be restacked later."

Each has an opt-in `--restack` flag and a config default:
`spice.repoSync.restack`, `spice.branchDelete.restack`, `spice.branchOnto.restack`
— and there are **nine** such `spice.*.restack` keys across the tool.

## The reason

*Not stated in the docs.* The inference is straightforward and well-supported:

**A conflict mid-`repo sync` leaves the user inside a rebase they did not ask
for.** `gs repo sync` is a routine, run-it-every-morning command; its job is to
pull trunk and clean up merged branches. If it also rebased, then any conflict in
any branch anywhere in the stack would halt it partway, with some branches
synced, some not, and the user in a detached conflict state — from a command they
thought was read-mostly. Separating the halves means sync always completes, and
the risky part is invoked deliberately, one branch at a time, when the user has
attention to spend.

The proliferation of nine per-command `restack` config keys suggests the default
was **contested**: users evidently want the bundled behaviour often enough that
every single site got a knob rather than a global one. **Inferred.**

## The trade-off you are choosing

The cost is a **temporarily inconsistent state**: metadata says `B` is based on
trunk, while `B`'s commits still sit on the old base. The tool knows the truth
and will tell you, but a user who stops after `repo sync` has a stack that is
correct on paper and wrong on disk. That is the price of never being ambushed by
a rebase.

Note this only works because the graph edit is *meaningful on its own*. If the
metadata were merely a cache of what the commits say, deferring the replay would
just be lying. It is meaningful here because the recorded base is the primary
truth — Git cannot derive it. So this pattern needs a real metadata layer, which
is what [[state-in-a-repository-ref]] provides.

## The general pattern

**Split declaring intent from realising it** when realisation can fail or block:

- database migrations: write the new schema definition, apply it separately
- infrastructure tools: `plan` and `apply`
- package managers: update the lockfile, install later
- here: retarget the base, replay the commits later

The shared property is that the declarative half is idempotent, instant, and
safe to run habitually — which is exactly what lets it be the *default*.

## Related

- [[state-in-a-repository-ref]] — the metadata being edited
- [[squash-merge-breaks-stacks]] — why the replay is needed so often
- [[stacked-changes]]
- [[stacked-branch-workflow]] — hub

[^cr]: [Change requests](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/cr.md), `doc/src/guide/cr.md`.
