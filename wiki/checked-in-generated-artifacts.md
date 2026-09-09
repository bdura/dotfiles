---
summary: A pattern — commit a generated file rather than generating it at build
  time, and guard it with a test that regenerates and diffs.
tags:
  - build-system
  - patterns
  - ci
---

# Checked-in generated artifacts

Sometimes a file is derived from other files in the repository, but generating it
during every build is not worth the dependency. The alternative is to generate
it, commit it, and add a test that regenerates it and diffs.

## Why do this

- The build no longer needs the generator's toolchain. Consumers who only want
  the product avoid installing it.
- The artifact can be embedded, byte-compiled or shipped with no build step.
- Reviewers see the derived change in the diff, which sometimes catches mistakes
  the source change alone would not reveal.

## What it costs

- A manual regeneration step that contributors will forget.
- The guard test must be able to run for the guarantee to hold. If it is gated
  on an optional toolchain, staleness can reach a release through any
  environment where the gate is not satisfied.
- Two things now claim to be the truth, and they can disagree between the moment
  of the source edit and the moment of regeneration.

## Instances

- fish commits `share/help_sections`, the topic index the `help` builtin
  validates against. It is produced by the Sphinx man build's
  `extract_sections` hook, embedded into the binary via `rust_embed`, and
  guarded by `tests/checks/sphinx-man.fish`, which regenerates and `diff -u`s
  it. That test is `#REQUIRES: command -v sphinx-build`, so the guarantee only
  holds where Sphinx is installed — a live instance of the gating hazard above.
  See [[fish-command-reference-pages]] and
  [[fish-docs-conventions-and-checks]].
