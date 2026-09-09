---
title: "docs: agent worktree convention follows the branch-per-tree model an ingested source argues against"
severity: low
---

## What

The global agent instructions (`~/.config/claude/CLAUDE.md`, reproduced into every
session) state:

> You may be inside a worktree dedicated to a feature branch. In that case, the
> worktree is located in `<repo-root>/.worktree/<branch-slug>/`.

That is **one worktree per branch** — worktrees used as a supplement to, or
replacement for, branching.

The source ingested into the wiki on 2026-09-09, matklad's *How I Use Git
Worktrees* (`.agent-workspace/sources/matklad-git-worktrees-per-activity.md`),
opens by rejecting exactly that model. Its author used worktrees that way, it
"didn't stick", and it was abandoned. The alternative proposed is a **fixed set
of trees, one per concurrent activity** (`main`, `work`, `review`, `fuzz`,
`scratch`), mostly uncorrelated to branches, with observer trees held in detached
HEAD. See `.agent-workspace/wiki/git-worktrees-per-activity.md`.

## Why it may not matter

The two are not straightforwardly in conflict:

- The source's objection to branch-per-worktree is about *human* context
  switching — the cost of carrying staged/unstaged state across a switch. Its
  replacement is to make throwaway commits (see
  `.agent-workspace/wiki/committing-instead-of-stashing.md`). An agent working in
  an isolated tree has a different problem: isolating concurrent *sessions* from
  each other, which is closer to the source's concurrency argument than to the
  branching one it dismisses.
- The source is one opinionated blog post, not a standard.

So this is recorded as a divergence to be aware of, not a defect to fix.

## Scope

No code in the `.dotfiles` repository implements worktree tooling. Searching the
tracked Nix, Fish, Lua and TOML files for `worktree` turns up only prose in agent
configuration (`.config/agents/skills/file-issue/SKILL.md`, `.config/pi/plan.md`,
`.config/pi/conversation.md`). The convention lives entirely in instruction text.

## Resolution paths

Any of these closes the issue:

1. Decide the current convention is right for agent use and add a sentence to the
   instructions saying why, so the divergence is deliberate rather than
   accidental.
2. Adopt something closer to the activity model if agent worktrees start being
   reused across tasks.
3. Decide the source is not authoritative here and close without change.
