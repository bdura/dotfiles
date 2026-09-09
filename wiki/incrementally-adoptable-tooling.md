---
summary: >
  Tooling designed so that no part of it is required: every automated step has
  a plain equivalent the tool accepts instead, so adoption is per-feature and
  reversible. The escape hatch treated as a design commitment.
sources:
  - git-spice @ 8b1262c3, doc/src/index.md
  - git-spice @ 8b1262c3, doc/src/guide/branch.md
tags:
  - design-decision
  - tooling
  - concept
  - adoption
---

# Incrementally adoptable tooling

A tool can demand that you adopt its model wholesale, or it can layer on top of
a model you already have and let you use as much of it as you like. The second
is much harder to build and much easier to adopt. [[git-spice]] is an unusually
disciplined example.

The stated commitment:

> "It works with Git instead of trying to replace Git. Introduce it in small
> places in your existing workflow without changing how you work
> wholesale."[^index]

> "git-spice does not require to change your workflow too drastically."[^branch]

## How the commitment is actually kept

The interesting thing is not the promise but the density of evidence that it is
paid for:

- **The home page's first code block pairs every command with its Git
  equivalent.** `git checkout -b feat1; gs branch track` **or** `gs branch
  create feat1`. `git rebase -i base` **or** `gs branch restack`. The tool
  documents how to not use it.[^index]
- **Initialisation is optional.** "This step isn't absolutely required.
  git-spice will initialize itself automatically when needed."[^stack]
- **Manual tracking exists so you can keep using plain Git.** `gs branch track`
  and `gs downstack track` retrofit the tool's model onto branches made with
  `git checkout -b`; `downstack track` "traverses the commit graph downwards from
  the current branch, identifying other branches that need to be tracked."[^branch]
- **Plain committing keeps working.** "With a stacked branch checked out, you can
  commit to it as usual with `git commit`, `git commit --amend`, etc." The
  wrappers are labelled, in the docs' own words, "convenience commands."[^branch]
- **The tutorial shows three ways to do each step**, in tabs labelled "git",
  "gs", and "gs shorthand".[^submit]
- **Shorthands are explicitly deferred.** "We encourage adopting the built-in
  shorthands **after** you are comfortable with the corresponding full command
  names."
- **It refuses to fight Git's native feature.** `rebase --update-refs` overlaps
  git-spice's core purpose, and the FAQ promises coexistence: a restack "will
  automatically detect that the branches are already properly stacked, and leave
  them as-is."[^faq]
- **You can use it against a forge it does not support.** `spice.submit.publish
  = false` disables the remote half and leaves the whole local model
  usable.[^recipes]

The `--update-refs` case is the strongest signal, because it is the expensive
one. Coexisting with a native feature that does the same job means restacking
must be **idempotent and no-op-detecting** rather than unconditional. That is a
real implementation constraint accepted purely so users are not made to choose.

## Why this is worth the trouble

- **Reversibility.** If nothing is required, nothing is a lock-in, and trying the
  tool is a cheap experiment rather than a migration.
- **Team adoption without consensus.** One person can use it while colleagues do
  not, because the artifacts it produces are ordinary branches and ordinary
  pull requests. A tool that changed the artifacts would need everyone to agree
  at once.
- **Graceful failure.** When the tool cannot handle something, the plain-Git path
  is still there. Contrast tools where an unsupported case leaves you stuck
  inside their abstraction.

## The cost, which is real

There are now **two ways to do most things, and they drift.** A branch created
with plain `git checkout -b` is silently untracked, and therefore invisible to
every stack operation — the model is in a state the user has no reason to expect.

The docs' own remedies are the tell that this bites: `spice.branchCheckout.
trackUntracked` exists to prompt about it, and `resources/recipes.md` publishes a
`post-checkout` hook to catch it automatically. That recipe reads git-spice's
internal ref directly, which the internals page tells you not to do — the
compromise leaks. See [[state-in-a-repository-ref]].

Generalising: **optional models need continuous reconciliation.** If users can
change the underlying state behind your back, you must either detect drift or
teach them a discipline — and teaching a discipline is exactly what "adopt it
incrementally" promised to avoid.

## A related but distinct move

Optional adoption is not the same as *degrading gracefully*, though they rhyme.
git-spice also does the latter: when no OS keyring is available it falls back to
a plain-text secrets file and **announces it at login, printing the path**. And
under environment-variable auth, `gs auth login` "will always fail" rather than
pretend to log in when the token is ambient. Both are refusals to be silently
weaker than advertised.

## Related

- [[git-spice]] — where the pattern is observed
- [[stacked-changes]] — the model being adopted incrementally
- [[stacked-branch-workflow]] — hub

[^index]: [Home](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/index.md), `doc/src/index.md`.
[^branch]: [Branch management](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/branch.md), `doc/src/guide/branch.md`.
[^stack]: [Get started: stack](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/start/stack.md), `doc/src/start/stack.md`.
[^submit]: [Get started: submit](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/start/submit.md), `doc/src/start/submit.md`.
[^faq]: [FAQ](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/faq.md), `doc/src/resources/faq.md`.
[^recipes]: [Recipes](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/recipes.md), `doc/src/resources/recipes.md`.
