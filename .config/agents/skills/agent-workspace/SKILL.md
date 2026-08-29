---
name: agent-workspace
description: Learn about the agent workspace.
---

# Agent workspace

You have access to a dedicated workspace located in `.agent-workspace`.
It contains an LLM wiki that stores a knowledge base relevant to the project.

It also contains three special directories:

- `specs/`: full specifications for future features
- `plans/`: implementation plans for those features
- `issues/`: (potential) issues detected while working on the project

Like the wiki, each directory contains an `index.md` file that allows the agent
to scan through elements. Every index entry follows one format:

```markdown
- [slug](path) — **status.** One line on what it is and where it stands.
```

## The workspace is a git worktree

`.agent-workspace` is a git worktree of the project repository, checked out on
the orphan `agent-workspace` branch. It shares the project's remote, so the
workspace travels with the repo while never appearing in the tree of `main`.
Git ignores registered worktree paths, which is why the project's status stays
clean without a `.gitignore` entry for it.

Two consequences:

- The workspace commits separately, on its own branch: `git -C .agent-workspace commit`.
  Never `git add .agent-workspace` from the project root.
- Finishing a piece of work usually means two commits — the code on the current
  branch, the workspace bookkeeping on `agent-workspace`.

If `.agent-workspace` exists but is not a worktree, say so rather than guessing
at how to commit it.
