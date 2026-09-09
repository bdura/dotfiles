---
summary: >
  Exploration of git-spice, a CLI for stacking Git branches and submitting them
  as dependent change requests to a forge. Read through its own documentation.
url: https://github.com/abhinav/git-spice
commit-hash: 8b1262c31f82591c8596a3646b474690f996e92a
tags:
  - git
  - stacking
  - project
  - cli
---

# git-spice

> "git-spice is a tool for stacking Git branches. It lets you manage and
> navigate stacks of branches, conveniently modify and rebase them, and create
> GitHub or GitLab Pull Requests or Merge Requests from them."[^index]

It is an implementation of a pre-existing practice rather than an invention of
one: the docs point outward to <https://www.stacking.dev/> for the practice
itself.[^index] See [[stacked-changes]] for the practice and its vocabulary.

The sentence that carries the whole design philosophy:

> "It works with Git instead of trying to replace Git. Introduce it in small
> places in your existing workflow without changing how you work
> wholesale."[^index]

That is not marketing — it is a constraint the codebase pays for repeatedly, and
it has its own page: [[incrementally-adoptable-tooling]].

## Why stack at all

The FAQ gives two reasons.[^faq] You **unblock yourself**, because you can start
the next branch while the current one is in review. And you are **kinder to your
team**: "A 100 line PR gets a more meaningful review than a 1000 line PR."

## The shape of the tool

Commands follow a `gs <scope> <verb>` grammar, where scope is one of `branch`,
`upstack`, `downstack`, `stack`, `repo`, `commit` and verb is `create`, `track`,
`restack`, `submit`, `merge`, `onto`, `delete`, `split` and so on. Learning the
four topological scope words yields the whole command matrix — `gs branch
restack`, `gs upstack restack`, `gs stack restack` — with no extra memorisation.
The scope words are exactly the vocabulary the docs teach in
[[stacked-changes]], so the CLI surface is a cross-product of the domain model's
own nouns.

*The docs never state this grammar explicitly; it emerges from the command
tables in the user guide. Inferred, not quoted.*

Local operations need no network: "All state is stored locally in your Git
repository. A network connection is not required, except when pushing or
pulling."[^index] How that store works, and what it costs, is on
[[state-in-a-repository-ref]].

## Design decisions with their own pages

- [[unit-of-review-commit-vs-branch]] — one change request per *branch*, not per
  commit, and the review-ergonomics argument for it. The best-argued decision in
  the documentation.
- [[incrementally-adoptable-tooling]] — every automated step has a plain-Git
  equivalent the tool will accept instead.
- [[state-in-a-repository-ref]] — tracking metadata as JSON blobs under
  `refs/spice/data`, versioned and auditable.
- [[metadata-update-vs-content-replay]] — graph edits are cheap and always
  succeed; rebasing is expensive and can conflict, so they are separated.
- [[subprocess-the-reference-implementation]] — no Git library; everything goes
  through the Git CLI's plumbing.
- [[squash-merge-breaks-stacks]] — the one external fact that most shapes the
  tool.

## Forge support

git-spice abstracts GitHub, GitLab, Bitbucket Cloud, Bitbucket Data Center,
Gitea, Forgejo and Azure DevOps behind a single seam — see
[[forge-and-change-request]] for the vocabulary and the limits.

The maintainer states a non-goal plainly: "we do not plan to implement support
for additional forges ourselves," followed by an invitation to open an issue
signalling interest, or to contribute with offered guidance.[^faq] The
abstraction's credibility is argued empirically rather than asserted: GitLab
support "was added by an external contributor without meaningful changes to the
rest of the codebase," and Bitbucket, Gitea, Forgejo and Azure DevOps arrived
"through the same forge boundary."[^faq]

## Stated limits and non-goals

- **Write access to the upstream repo is required** for stacked change requests,
  because a CR for a stacked branch must target another branch in the same
  repository.[^limits]
- **Fork mode only submits trunk-based branches.** Stacked branches get pushed
  to the fork but receive no CR "until their base branch is merged and they are
  restacked on top of trunk." GitHub App authentication is incompatible with
  fork mode.[^limits]
- **Some repository policies cannot host a stacked workflow at all.** Where
  changing a PR's base branch dismisses approvals, the docs say: "There is no
  workaround to this except to reconfigure the repository as this setting is
  fundamentally incompatible with a PR stacking workflow."[^limits] This is the
  strongest statement in the documentation.
- **Per-forge feature gaps**, each labelled "These are platform limitations, not
  git-spice limitations": Bitbucket Cloud has no labels or assignees, Azure
  DevOps has reviewers but no assignees, Bitbucket Data Center cannot change
  draft status after creation.[^limits]
- **Internals are explicitly unstable** — see [[state-in-a-repository-ref]].
- **Experimental features "may destroy your work"** — the warning is that
  blunt.[^exp]
- Linux and macOS are "fully supported", Windows since v0.6.0; Git 2.38 is the
  floor.[^install]

## Unusual transparency artifacts

`resources/llms.md` discloses LLM use in the project's own development and names
the last release free of LLM-generated code (v0.15.0), prefaced with "If LLM
usage in development is a concern for you."

`guide/internals.md` exists to document the metadata format for "the curious,
and in the interest of transparency," while warning readers off depending on it.

## Documentation bugs found while reading

Worth reporting upstream if anyone gets round to it:

- `resources/recipes.md` still lists Azure DevOps as an example of an
  *unsupported* forge, though four other pages document it as supported.
- The `--update-only` example output in `guide/cr.md` reads
  `goat: Updated #2` where the stack in that same example requires
  `fish: Updated #2`.
- `README.md` omits Azure DevOps from its forge list while `doc/src/index.md`
  includes it.

## Edges of this reading

This exploration read the documentation, not the Go implementation. Claims about
internals are the docs' own unless marked inferred. Not read: the generated CLI
reference (`doc/includes/cli-reference.md`), roughly 60% of the ~75 config key
bodies, and the changelog — so there is **no release-history narrative** here,
only per-feature "introduced in" versions from inline markers.

The documentation *toolchain* — the CLI-reference generator, strict anchor
validation as a completeness check, build-time SVG rendering — was explored but
deliberately left unwritten, per the chosen focus on docs-as-source.

## Related

- [[stacked-branch-workflow]] — hub
- [[git-workflow]] — the broader Git-practice hub

[^index]: [git-spice home](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/index.md), `doc/src/index.md`.
[^faq]: [FAQ](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/faq.md), `doc/src/resources/faq.md`.
[^limits]: [Limitations](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/limits.md), `doc/src/guide/limits.md`.
[^exp]: [Experiments](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/cli/experiments.md), `doc/src/cli/experiments.md`.
[^install]: [Installation](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/start/install.md), `doc/src/start/install.md`.
