---
name: deslop
description: Strip AI residue from the code — restated comments, conversational leftovers, changelog-in-code.
disable-model-invocation: true
user-invocable: true
---

# De-slop

A repo is a working snapshot of a project, not a transcript of how it got there.
This skill removes the residue: comments that restate the code, leftovers from a
conversation the reader was not part of, prose that reads like it was sold to you.

The cutting is done by the `deslop` agent, dispatched fresh. That matters —
this session remembers why each comment was written and would defend it.
A cold agent sees what a cold reader sees. You handle git and verification;
it only edits.

## 1. Resolve the scope

Use the paths the user named. Otherwise take the files the current branch changed
against `main`. If the branch *is* `main` or the diff is empty, ask for paths
rather than sweeping the tree.

Exclude `CHANGELOG.md`, anything under `.agent-workspace`, vendored and generated
files. Those are records or output, not the snapshot.

## 2. Stage first

The agent cuts aggressively, so the undo has to be real. Stage the target paths
before dispatching: the cuts then land as unstaged changes on top, `git diff`
shows exactly what the agent removed and nothing of the user's own work,
and `git checkout --` reverts the cuts alone.

If the index already holds a partial commit, leave it alone and say so — the user
was building something deliberate, and the isolation is weaker for this run.

## 3. Dispatch

Send the file list to the `deslop` agent. Split into batches of a few files
if the list is long; the reports concatenate. You can spawn multiple agents in
parallel in that case.

## 4. Verify and report

The agent's diff should be a no-op. Check it: run the project's test command
and typechecker, and report the tail. If neither exists, say so plainly rather
than implying the cuts were checked.

Then relay the agent's report — the borderline cuts especially, quoted, since the
user reads those instead of the diff. File the code-shape slop it listed with
/file-issue, or fold it into the report if the repo has no workspace.

Do not commit. The user reviews and commits.
