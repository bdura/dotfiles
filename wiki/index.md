# Wiki index

Knowledge base for this project. Entry point: follow a hub page to reach everything
else.

## Hubs

- [[git-workflow]] — Git working practices: worktree layout, and how work in
  progress is parked and resumed.
- [[stacked-branch-workflow]] — shaping chains of dependent branches and getting
  each reviewed separately, with the design decisions such tooling must make.

## Explored projects

Each project page is its own hub for that project's pages.

- [[git-spice]] — CLI for stacking Git branches and submitting them as dependent
  change requests to a forge. Read through its own documentation.
- [[fish-shell]] — the friendly interactive shell, whose oddities are argued from
  five named design laws. Read through its own documentation and docs toolchain.

## Cross-cutting patterns

General patterns instantiated by more than one explored project.

- [[docs-driven-by-production-tools]] — invoke the real tool from the docs build
  rather than reimplementing its behaviour, so the docs cannot drift.
- [[checked-in-generated-artifacts]] — commit the generated file and guard it
  with a regenerate-and-diff check.
