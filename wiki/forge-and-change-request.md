---
summary: >
  "Forge" as the interchangeable category of code-hosting platforms, and
  "change request" as the forge-neutral noun for the reviewable unit that
  GitHub calls a pull request and GitLab calls a merge request.
sources:
  - git-spice @ 8b1262c3, doc/src/guide/concepts.md
  - git-spice @ 8b1262c3, doc/src/guide/limits.md
tags:
  - git
  - forge
  - vocabulary
  - concept
---

# Forge and change request

Two pieces of vocabulary that any writing about review workflows needs, and that
most tools leave implicit by hardcoding GitHub's nouns.

## Forge

A **forge** is a code-hosting platform that offers repository hosting plus a
review surface: GitHub, GitLab, Bitbucket Cloud, Bitbucket Data Center, Gitea,
Forgejo, Azure DevOps. Treating them as one substitutable category — rather than
"GitHub, and some others we might get to" — is a design position, not just a
word.

[[git-spice]] makes the category a code boundary: "most of the code is
forge-agnostic, with forge-specific code … isolated to their own directories
inside `internal/forge/`."[^faq]

### Why the abstraction is credible

The docs argue it **empirically instead of asserting it**, which is a standard
worth borrowing for any claimed extension point:[^faq]

- integration tests run against a *simulated* forge, so the seam is exercised
  without network;
- GitLab support "was added by an external contributor without meaningful
  changes to the rest of the codebase";
- Bitbucket arrived across four PRs, likewise;
- Gitea, Forgejo and Azure DevOps came "through the same forge boundary."

An abstraction that outsiders have successfully extended, repeatedly, without
touching the core is demonstrated rather than claimed. Contrast the usual "we
have a plugin interface" with no evidence anyone but the author has used it.

### The seam plus a stated non-goal

Having built the seam, the maintainer declines to keep using it: "we do not plan
to implement support for additional forges ourselves… If you would like to see
support for a specific forge, please open an issue signaling your interest. If
you have the time and inclination to contribute, mention that… and we will be
happy to provide guidance."[^faq]

This is capacity management as project governance: keep the extension point
open, refuse the ongoing labour, and route demand into an issue that *measures*
interest rather than a backlog that implies commitment.

## Change request

> "A **Change Request** (CR) is a single merge-able unit of work submitted to
> GitHub, GitLab, Bitbucket, Gitea, Forgejo, or Azure DevOps. Each Change
> Request corresponds to a branch."[^concepts]

The term is coined because these are Pull Requests everywhere except GitLab,
where they are Merge Requests. Rather than privilege one forge's noun, the docs
made a neutral one. The rename left a trace: the docs site permanently redirects
`guide/pr.md` to `guide/cr.md`.

"Each Change Request corresponds to a branch" is not a definition detail but the
consequence of a decision — see [[unit-of-review-commit-vs-branch]].

### Submitting

**Submitting** is the docs' word for create-or-update, and it is deliberately
idempotent: "change requests will be created for branches that don't already
have them, and updated for branches that do."[^cr] One verb, safe to repeat,
which is what lets `gs stack submit` be run habitually.

## Remote topology vocabulary

- **Upstream remote** — "The Git remote that hosts the trunk branch and receives
  Change Requests."[^concepts]
- **Push remote** — "The Git remote that receives submitted branch
  pushes."[^concepts]
- **Fork mode** — when the two differ: push branches to your fork, open change
  requests against upstream.[^concepts]

Fork mode is where the abstraction runs out. Stacked branches can be pushed to a
fork but get no CR "until their base branch is merged and they are restacked on
top of trunk," because a stacked CR must target another branch in the *upstream*
repository.[^limits] The docs are honest that "To submit a fully stacked series
of Change Requests, push access to the upstream repository is still required" —
which means **the classic open-source fork workflow cannot host a stack.**

## Where forges are not interchangeable

Per-forge gaps, each labelled "These are platform limitations, not git-spice
limitations":[^limits] Bitbucket Cloud has no labels and no assignees, and needs
fixed template paths because it exposes no template-listing API; Bitbucket Data
Center needs 8.18+ for drafts and cannot change draft status after creation, and
has no cross-repo PRs; Azure DevOps has reviewers but no assignees.

Careful attribution of a limitation to the platform rather than the tool is
itself good documentation practice: it tells the reader whether waiting will
help.

## Related

- [[stacked-changes]] — the local half of the model
- [[git-spice]]
- [[stacked-branch-workflow]] — hub

[^concepts]: [Concepts](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/concepts.md), `doc/src/guide/concepts.md`.
[^faq]: [FAQ](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/resources/faq.md), `doc/src/resources/faq.md`.
[^cr]: [Change requests](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/cr.md), `doc/src/guide/cr.md`.
[^limits]: [Limitations](https://github.com/abhinav/git-spice/blob/8b1262c3/doc/src/guide/limits.md), `doc/src/guide/limits.md`.
