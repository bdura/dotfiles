---
name: fix-issue
description: Fix an issue filed in the agent workspace.
disable-model-invocation: true
user-invocable: true
---

# Fix an issue

Read `.agent-workspace/issues/index.md`. If the user named an issue, work that one;
otherwise list what is open with its severity and ask which to take.

Read the issue file in full. It was written to stand alone, but it may have
been filed a while ago: check that the problem still exists before fixing it.
If it is already gone, close it and say so rather than inventing work.

Fix it. Use /tdd for anything behavioural — an issue describing a bug is a failing
test waiting to be written, so write that test first and watch it fail for the
stated reason.

## Closing

An issue is closed by deletion, not by a status field:

1. Commit the fix to the current branch, with a one-liner conventional commit.
2. Delete `.agent-workspace/issues/<slug>.md` and its line in `issues/index.md`.
3. Commit the workspace: `git -C .agent-workspace commit`.

If the fix turns out to be larger than an issue — a feature in disguise —
stop and say so. That belongs in /to-spec, not here.
