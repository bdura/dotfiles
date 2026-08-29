---
name: llm-wiki
description: Query or maintain a knowledge base in the form of an LLM-wiki
---

# LLM Wiki

A knowledge base maintained by an LLM agent.

## Purpose

A wiki is a structured, interlinked knowledge base. The agent maintains the wiki.
The human curates sources, asks questions, and guides the analysis.

## Folder structure

The wiki lives in the agent workspace, alongside `specs/`, `plans/` and `issues/`:

```raw
.agent-workspace/
├── inbox/         -- transient source documents for the agents to ingest
├── sources/       -- persistent source documents (append-only)
├── .repos/        -- external repositories cloned for study (never committed)
└── wiki/          -- markdown pages maintained by the agent
    └── index.md   -- entry point to the wiki
```

Pages should be as "atomic" as possible, meaning they should ideally cover a single
concept or topic. They can however be regrouped through the use of "top-level"
or "hub" pages that serve as intermediate index pages for efficient navigation
through the wiki.

`wiki/index.md` is the entry point, not an exhaustive listing: it need not link
every page directly, but every page must be reachable from it by following the
index-then-hub-page hierarchy.

## Rules

- Never modify anything in the `sources/` folder
- Always update `wiki/index.md` or the relevant hub page after changes
- Keep page names lowercase with hyphens (e.g. `machine-learning.md`)
- Write in clear, plain language

## Specific instructions

- [Create a new entry](./references/create-entry.md)
- [Ingest a source](./references/ingest.md)
- [Navigate the wiki](./references/navigation.md)
- [Explore a repository for ingestion into the wiki](./references/explore-repo.md)
