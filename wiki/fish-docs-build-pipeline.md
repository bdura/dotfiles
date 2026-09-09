---
summary: How fish's Sphinx docs are built and installed — two entry points via
  cargo xtask and CMake, man pages produced as a side effect of a Cargo build
  script, and a deliberately fail-loud policy because the docs back --help.
sources:
  - doc_src/conf.py
  - crates/xtask/src/main.rs
  - crates/build-man-pages/build.rs
  - cmake/Docs.cmake
  - cmake/Install.cmake
tags:
  - fish-shell
  - documentation
  - build-system
---

# fish docs build pipeline

reStructuredText in `doc_src/`, built with Sphinx.[^contrib] Three builders are
in play: `html` for the website, `man` for man pages, and `markdown` via
`sphinx_markdown_builder` when that package is importable.[^conf-md] The
Markdown builder's purpose is not explained in the repo — **needs
verification**; the plausible reading is a machine-readable copy for tooling.

## Two entry points, both indirect

**`cargo xtask html-docs`** builds a debug `fish_indent` (`--no-default-features`)
unless given one, symlinks it into a temporary directory prepended to `PATH`
"to avoid adding other binaries to the PATH", then runs
`sphinx-build -j auto -q -b html -c doc_src -d <target>/.doctrees-html doc_src
<target>/fish-docs/html`.[^xtask] The `fish_indent` dance is required because
the docs' syntax highlighter shells out to it — see
[[fish-docs-sphinx-extensions]].

**`cargo xtask man-pages`** is not a Sphinx invocation at all. It runs
`cargo build --package fish-build-man-pages`, and that crate's `build.rs` is
what calls Sphinx: `sphinx-build -j auto -q -b man -c doc_src doc_src
<doc-dir>/man/man1`, with the doctree directory placed *above* `man1`
deliberately so the ~6 MB of doctrees are excluded from the embedded
output.[^buildrs]

**CMake** wraps both as `sphinx-docs` and `sphinx-manpages`, aggregated into
target `doc`, passing `FISH_SPHINX` and `CARGO_TARGET_DIR` through the
environment.[^cmake] `WITH_DOCS` defaults on iff `sphinx-build` was found, and
CMake *errors* if a user forces `WITH_DOCS=ON` without Sphinx[^cmake] — docs are
opportunistic but never silently skipped when requested. `GNUmakefile` is a thin
wrapper over CMake and does not mention docs.

## Fail loud, on purpose

`build.rs` documents its own error policy: "Every error here is fatal so cargo
doesn't cache the result — if we skipped the docs with sphinx not installed,
installing it would not then build the docs." Opting out therefore requires an
explicit `FISH_BUILD_DOCS=0`, which the comment concedes "is unfortunate - but
the docs are pretty important because they're also used for `--help`."[^buildrs]

That last clause is the whole justification for the pipeline's weight. Man pages
are not a nicety; they are the runtime help system, which is the law of
discoverability from [[fish-design-principles]] cashed out as a build
dependency. See [[fish-command-reference-pages]].

There is one carve-out: `cargo clippy` skips the man build, because
`rust-embed` panics when asked to embed a directory that does not
exist.[^buildrs]

## Installation

HTML goes to `CMAKE_INSTALL_DOCDIR`, marked OPTIONAL so it is skipped when
Sphinx never ran.[^install] Man pages are installed twice over: the whole
generated tree lands in fish's private manpath `${datadir}/fish/man/man1`, while
a curated subset goes to the *system* manpath — "these are the man pages that go
in system manpath; all manpages go in the fish-specific manpath".[^install] The
subset is `fish.1`, `fish_indent.1`, `fish_key_reader.1` and the multi-page
manuals (`fish-doc`, `fish-tutorial`, `fish-language`, `fish-interactive`,
`fish-terminal-compatibility`, `fish-completions`, `fish-prompt-tutorial`,
`fish-for-bash-users`, `fish-faq`). Two pages are excluded per platform:
`open.1` on macOS ("we defeat fish's open function on OS X") and `realpath.1`
elsewhere.[^install]

`conf.py` sets `man_make_section_directory = False` explicitly to work around a
newer-Sphinx regression that would nest the output in an extra directory and
break this layout.[^confman]

## Version strings

`release` and `version` come from running `build_tools/git_version_gen.sh`, not
from a literal in `conf.py`,[^confver] so built docs always report the exact
build. The `help` builtin relies on this when falling back to the hosted copy.

## Toolchain pinning

`.github/actions/install-sphinx` pins the Python side with `uv` against
`pyproject.toml`/`uv.lock` — `sphinx>=9.1` and `sphinx-markdown-builder` pinned
to a specific revision of a fork — runs `uv lock --check` to fail CI on a stale
lockfile, and smoke-imports both packages. See
[[fish-docs-conventions-and-checks]].

[^contrib]: [`CONTRIBUTING.rst`:104-125](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/CONTRIBUTING.rst#L104-L125)
[^conf-md]: [`doc_src/conf.py`:18-25](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L18-L25)
[^xtask]: [`crates/xtask/src/main.rs`:87-141](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/crates/xtask/src/main.rs#L87-L141)
[^buildrs]: [`crates/build-man-pages/build.rs`](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/crates/build-man-pages/build.rs)
[^cmake]: [`cmake/Docs.cmake`:14-60](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/cmake/Docs.cmake#L14-L60)
[^install]: [`cmake/Install.cmake`:33-58](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/cmake/Install.cmake#L33-L58)
[^confman]: [`doc_src/conf.py`:231](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L231)
[^confver]: [`doc_src/conf.py`:120-128](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L120-L128)
