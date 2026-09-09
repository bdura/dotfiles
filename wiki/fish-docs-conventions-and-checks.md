---
summary: What fish enforces automatically about its documentation (two
  littlecheck tests, a pinned Python toolchain, a build that fails on a missing
  description) and what it leaves to human eyeballs.
sources:
  - CONTRIBUTING.rst
  - tests/checks/sphinx-man.fish
  - tests/checks/help-completions.fish
  - pyproject.toml
tags:
  - fish-shell
  - documentation
  - ci
  - conventions
---

# fish docs: conventions and checks

## What CONTRIBUTING says

Docs live in `doc_src/`, RST plus Sphinx, with `doc_src/cmds/` for builtins and
functions. Three equivalent local builds are offered — `cargo xtask html-docs`,
`cmake --build build -t sphinx-docs`, or a raw
`sphinx-build -j auto -b html doc_src/ /tmp/fish-doc/`. The sign-off is manual:
"open the HTML docs in a browser and see that it looks okay."[^contrib]

There is **no prose linter** — no `doc8`, `rstcheck` or `vale` anywhere in
`.github/`, `pyproject.toml` or `build_tools/`. Style, tone and wording are
reviewed by people, not tools.

`doc_internal/` exists but is not about documentation authoring: it holds the
C++→Rust port plan, macOS release-artifact notes and the Rust development guide.
The reasoning behind the doc tooling lives in comments inside `conf.py`,
`fish_synopsis.py` and `build.rs` instead.

## What is enforced

**Structural correctness, via the build.** A `cmds/*.rst` page missing its
`<name> - <description>` first line raises `SphinxWarning` and fails the doc
build, which CI runs because `WITH_DOCS` defaults on wherever Sphinx is present.
See [[fish-command-reference-pages]] and [[fish-docs-build-pipeline]].

**Two littlecheck tests under `tests/checks/`**, both gated on
`#REQUIRES: command -v sphinx-build` so they run only where Sphinx is installed
(CI installs it):

- `sphinx-man.fish` runs the man build with
  `-D fish_help_sections_output=$PWD/help_sections` and `diff -u`s the result
  against the committed `share/help_sections`. This is the only thing keeping
  that generated file honest.
- `help-completions.fish` cross-checks the topics `share/completions/help.fish`
  offers against `status get-file help_sections`, so the completion script and
  the doc-derived section list cannot drift apart.

`build_tools/check.sh` is the general check driver (`FISH_CHECK_LINT`-gated
linting plus the littlecheck suite); it does not special-case docs, the two
tests above simply live in the suite.

**The Python toolchain**, pinned with `uv` against `pyproject.toml`/`uv.lock`
(`sphinx>=9.1`, `sphinx-markdown-builder` at a specific revision of a fork),
with `uv lock --check` failing CI on a stale lockfile plus a smoke import of
both packages.[^pyproject]

## What is not checked

No spell checker. No link checker in CI — `conf.py` sets `linkcheck_ignore` for
GitHub issue URLs,[^linkcheck] which implies Sphinx's `linkcheck` builder is run
sometimes, but no workflow step invoking it was found. **Needs verification.**

Also unverified: which CI jobs publish the built docs to fishshell.com.
`.github/workflows/` was only skimmed for the Sphinx install action.

## Localization does not cover the docs

`localization/` (gettext `po/*.po`, Fluent `fluent/*.ftl`) translates fish's
**runtime** messages only — errors and prompts emitted by the shell, from Rust
via `localize!`/`wgettext!` and from fish scripts via the `_` builtin.[^l10n] It
does not touch `doc_src/`, and this repository contains no mechanism for
translating the Sphinx documentation. Checked explicitly, since it is an easy
thing to assume exists.

[^contrib]: [`CONTRIBUTING.rst`:104-125](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/CONTRIBUTING.rst#L104-L125)
[^pyproject]: [`pyproject.toml`:11-19](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/pyproject.toml#L11-L19)
[^linkcheck]: [`doc_src/conf.py`:301](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L301)
[^l10n]: [`CONTRIBUTING.rst`:253-575](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/CONTRIBUTING.rst#L253-L575)
