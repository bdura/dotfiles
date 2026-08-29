## Exploring an external repository

Clone the repository into `.agent-workspace/.repos/<repo-name>/`. That directory
must be listed in the workspace's own `.gitignore` — clones are working material
and never belong in a commit. If the clone already exists, update it as described
below.

Explore the repository:

- Find out the general purpose of the project
- Make a list of important features
- Explore the project's architecture and insist on the main design decisions
  and (if possible), why they were made

Create (or update) a page for the repository as a whole, plus a page for each
salient features, important design decisions with their implications, etc. Make
sure to link those to general concepts already present in the wiki to accumulate
knowledge.

Specific implementation of a feature/concept for that project should land in
a dedicated page that links the two, and explains the architecture choice,
what it allows and its limits.

When updating a project's pages in the wiki, make sure that every page formerly
linked is up-to-date with the new version. Pages that are not relevant anymore
(because the repo changed) should say so.

Respect the following template for the main entry:

```markdown
---
summary: Exploration of <project name>
url: <repo URL>
commit-hash: <commit the pages describe>
---

# Project name
```

### Pinning and updating

The clone is pinned to the commit recorded in `commit-hash`, so it is left in a
detached checkout. Never `git pull` it — that will fail or silently move you off
the pinned commit.

To update: `git fetch`, pick the commit you now want to describe, `git checkout`
that commit, then revise the pages and set `commit-hash` to match. The frontmatter
and the working tree must always agree.
