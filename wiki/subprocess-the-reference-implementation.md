---
summary: >
  Driving the canonical tool's machine-facing interface as a subprocess instead
  of reimplementing or linking a third-party library, when correctness against
  a moving target matters more than performance.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/internals.md
  - git-spice @ 8b1262c3, doc/src/guide/troubleshooting.md
tags:
  - design-decision
  - architecture
  - concept
---

# Subprocess the reference implementation

[[git-spice]] does not link a Git library. Every operation runs the real `git`
binary:

> "git-spice does not use a third-party Git implementation. All operations are
> performed directly against the Git CLI, often relying on Git's plumbing
> commands."[^internals]

## The stated why

Under a "Why?" admonition in the docs:

> "Most third-party Git implementations trail behind in feature parity. For
> example, many third-party implementations can misbehave when you make use of
> advanced features like `git worktree`, `git sparse-checkout`, or sparse
> indexes. By relying on the highly scriptable and machine-consumable Git
> plumbing we don't have to deal with those issues."[^internals]

This is **correctness by delegation**: whatever Git supports, git-spice supports,
including features that did not exist when git-spice was written. A tool that
manipulates other people's repositories cannot know in advance which exotic
features are in use, and a reimplementation's blind spots become the tool's
data-loss bugs.

The named examples are well chosen. Worktrees and sparse checkouts are exactly
where library reimplementations diverge, because they complicate the
repository-layout assumptions such libraries bake in. And worktrees are not
hypothetical for this tool's users — see [[git-worktrees-per-activity]].

## The bill, which shows up in the user-facing docs

The costs are not hidden; they surface as documented problems:

- **Lock contention.** `spice.git.indexLockTimeout` exists because "git-spice
  will detect and retry Git commands that fail due to `index.lock` contention."
  A library holding the index in-process would not race with itself.
- **Concurrency with other Git processes.** The troubleshooting page documents
  `fatal: Cannot rebase onto multiple branches.` caused by "background Git
  processes that are running concurrently with git-spice operations" — shell
  prompt plugins and editor autofetch being the named culprits.[^trouble] This is
  the deep cost: the repository is a shared mutable resource with no lock
  protocol, and subprocessing puts you in the same contention pool as every
  status-line in the user's terminal.
- **A version floor.** Git 2.38 minimum, because the plumbing you rely on has to
  exist.
- **Process spawn overhead and output parsing** on every operation.

## Plumbing, not porcelain

The distinction carries the design. Git's *porcelain* commands are for humans and
their output may change; its *plumbing* is documented as machine-consumable and
stable. Subprocessing is only a durable strategy where the tool offers such an
interface — the docs' phrase is "highly scriptable and machine-consumable". A
tool without a stable machine interface makes this approach output-scraping
instead, which is a different and much worse bet.

## Not a licence to shell out freely

The repo's own contributor guidance says the opposite-sounding thing: "Do not
shell out casually. When git-spice needs another process, wrap that process
behind a concrete library-like API."[^design]

Read carefully, the two rules agree. The decision is not "subprocess is fine
everywhere" but **subprocess Git, behind a typed internal API**. The constraint
is about *which* dependency is authoritative, not about whether spawning
processes is acceptable. The wrapper is what keeps parsing and error handling in
one place — so callers program against a library and only the boundary knows
there is a process.

The two sentences read as opposed, which is worth flagging to anyone reading both
documents.

## When to reach for this

Good bet when: the canonical implementation is a hard dependency anyway; it
exposes a documented machine interface; correctness on edge cases matters more
than per-call latency; and the feature surface moves faster than you can track.

Bad bet when: you need many small calls in a hot loop; the tool has no stable
machine interface; you must run where the binary may be absent; or you need
transactional control over shared state the binary does not lock.

## Related

- [[git-spice]]
- [[git-worktrees-per-activity]] — a feature named as the reason libraries fail
- [[stacked-branch-workflow]] — hub

[^internals]: [Internals](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/internals.md), `doc/src/guide/internals.md`.
[^trouble]: [Troubleshooting](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/troubleshooting.md), `doc/src/guide/troubleshooting.md`.
[^design]: `.agents/docs/design.md` in the git-spice repository at 8b1262c3 — contributor guidance, not user documentation.
