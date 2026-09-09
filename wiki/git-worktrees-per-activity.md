---
summary: >
  Worktrees used as a means to manage concurrent activities rather than as a
  replacement for branches: a small fixed set of trees, each dedicated to one
  thing that can be happening at the same time as the others.
sources:
  - .agent-workspace/sources/matklad-git-worktrees-per-activity.md
tags:
  - git
  - worktrees
  - workflow
---

# Worktrees per concurrent activity

Most writing about `git worktree` presents it as a replacement for, or supplement
to, branches: instead of switching branches you change directories. This source
rejects that framing — the author tried it and abandoned it.[^src] The workflow
that stuck instead maps worktrees onto *concurrent activities*.

The trees are:

- **fixed in number** (five, in the author's case),
- **mostly uncorrelated to branches**,
- each dedicated to one activity that proceeds alongside the others.[^src]

## The test

The question a tree must answer is not "what branch is this?" but "can this be
happening at the same time as that?" You cannot write code and review code
simultaneously — but the review sits open while the implementation proceeds, so
the two get separate trees. A fuzzer chews on your code while you keep editing
it, so fuzzing gets its own tree.[^src]

Branch switching, on its own, is not a reason to create a tree. That problem is
solved separately — see [[committing-instead-of-stashing]].

## The five trees

| Tree | Purpose |
| --- | --- |
| `main` | A read-only snapshot of the remote main branch, used to compare against the code being written or reviewed.[^src] |
| `work` | Where most code is written. Switches branches constantly.[^src] |
| `review` | Where someone else's code is checked out for review.[^src] |
| `fuzz` | Runs long fuzzing jobs against the code being actively worked on.[^src] |
| `scratch` | Arbitrary unrelated things noticed mid-task.[^src] |

`main` exists because comparison is not limited to reading source. The source
lists "how long the build takes" and "what is the behavior of this test" as
things you want to check against the pristine version — which needs a real,
buildable checkout, not a diff.[^src]

`scratch` catches the drive-by. While reviewing a PR you notice an unrelated
typo; the fix is prepped in `scratch` on its own branch and pushed without
disturbing either the review or the work in progress.[^src]

## Detached HEAD

The source calls it crucial that the fuzzing tree operates in detached HEAD
state, via `git switch -d <hash>`.[^src] The reason follows from the concurrency
framing: the fuzzer must be pinned to the exact commit it started on, while
`work` continues to move that branch forward underneath it. A tree tracking a
branch would drift; a detached one is a stable snapshot.

More generally, the source notes `-d` is "very helpful with this style of
worktree work" — trees that observe rather than author should not hold a
branch.[^src]

The typical loop: commit everything in `work`, copy the hash, switch to `fuzz`,
`git switch -d` onto that hash, and start the job. Editing and history-cleaning
continue in `work` while the fuzzer runs; if it stays quiet, the branch is
force-pushed and a PR opened.[^src]

## Adjacent habits

Two smaller practices appear in the same workflow, neither specific to
worktrees:

- Branch names are prefixed with the author's username (`matklad/feature`),
  because the team works from a centralized repo rather than personal forks.[^src]
- For more complicated features, work starts with an *empty* commit whose
  message is written first — described as a way to collect your thoughts and
  discover dead ends "more gracefully than hitting a brick wall coding at 80
  WPM".[^src]

## Related

- [[committing-instead-of-stashing]] — how branch switching is handled without
  worktrees
- [[git-workflow]] — hub

[^src]: [How I Use Git Worktrees](../sources/matklad-git-worktrees-per-activity.md),
    matklad, 2024-07-25.
