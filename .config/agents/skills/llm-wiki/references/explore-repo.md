## Exploring an external repository

To explore an external repository, clone it in `./.repos/`. If it already exists,
update it.

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
commit-hash: <latest checked out commit>
---

# Project name
```

Modify the commit hash upon update.
