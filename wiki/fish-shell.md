---
summary: Exploration of fish-shell, the friendly interactive shell — read through
  its own documentation, both the prose and the toolchain that builds it.
url: https://github.com/fish-shell/fish-shell
commit-hash: 79f79059dbd9f5071b98418509fd72d59503aafb
---

# fish-shell

fish is "the **f**riendly **i**nteractive **sh**ell": a Unix shell whose stated
focus is usability and interactive use rather than POSIX script portability.[^index]
Its three headline claims are an extensive UI (syntax highlighting,
autosuggestions, tab completion, navigable selection lists), "no configuration
needed", and easy scripting.[^index]

This exploration was scoped to **the documentation** — what fish's own docs say,
and how they are produced. The Rust implementation under `src/` was not read, so
every behavioural claim below is reported as the documentation's claim, not as
verified behaviour.

## Why fish is worth studying

fish is unusual among shells in shipping an explicit, argued design document.
Nearly every concrete oddity — no heredocs, no subshells, no `$((...))`,
no configurable history size — is presented as a consequence of one of five
named "laws". [[fish-design-principles]] is therefore the hub to read first;
the other pages instantiate it.

## The shell

- [[fish-design-principles]] — the three goals and five laws, and the tension
  the docs leave unresolved.
- [[fish-posix-divergences]] — the catalogue of deliberate breaks with
  POSIX/bash, each traced to a principle.
- [[fish-set-time-word-splitting]] — the load-bearing semantic divergence:
  variables split when *set*, not when *used*.
- [[fish-variable-scopes]] — universal/global/function/local, and why
  "exported" is a state rather than a scope.
- [[fish-autoloading]] — lazy loading of functions and completions, the
  responsiveness law made mechanical.
- [[fish-feature-flags]] — fish's staged process for shipping breaking changes.
- [[fish-completions]] — how completions are written and discovered.
- [[fish-interactive-features]] — autosuggestions, highlighting, abbreviations,
  bindings, history.
- [[fish-terminal-handling]] — fish queries the terminal directly and does not
  read terminfo.

## The documentation itself

- [[fish-docs-information-architecture]] — 15 top-level documents plus 126
  command pages, and the two competing orderings they are presented in.
- [[fish-docs-build-pipeline]] — Sphinx, two entry points, and how man pages
  get built by a Cargo build script.
- [[fish-docs-sphinx-extensions]] — the `synopsis` directive and the
  `fish_indent`-backed Pygments lexer.
- [[fish-command-reference-pages]] — the house style for `doc_src/cmds/`,
  prose transclusion, and how the `help` builtin resolves a topic.
- [[fish-docs-conventions-and-checks]] — what is enforced automatically and
  what is left to "open it in a browser and see that it looks okay".

## General patterns this repo instantiates

- [[docs-driven-by-production-tools]] — via [[fish-docs-sphinx-extensions]].
- [[checked-in-generated-artifacts]] — via `share/help_sections`, see
  [[fish-command-reference-pages]].

## Reading it yourself

The clone lives at `.repos/fish-shell`, detached at the commit in this page's
frontmatter. It is pinned: never `git pull` it. To move to a newer commit,
`git fetch`, `git checkout <commit>`, re-explore, and update `commit-hash`
here along with any page it invalidates.

[^index]: [`doc_src/index.rst`:7-17](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L7-L17)
