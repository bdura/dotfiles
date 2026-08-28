---
name: agent-workspace
description: Learn about the agent workspace. Activate whenever there is a `.agent-workspace` directory at the project root.
---

# Agent workspace

You have access to a dedicated workspace located in `.agent-workspace`.
It contains an LLM wiki that stores a knowledge base relevant to the project.

It also contains three special directories:

- `specs/`: full specifications for future features
- `plans/`: implementation plans for those features
- `issues/`: (potential) issues detected while working on the project

Like the wiki, each directory contains an `index.md` file that allows the agent
to scan through elements.
