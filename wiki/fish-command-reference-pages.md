---
summary: The house style for doc_src/cmds/ — a parsed title line, a synopsis
  block, marker-comment transclusion for near-duplicate pages — and how the help
  builtin resolves a topic to a page.
sources:
  - doc_src/cmds/string.rst
  - doc_src/cmds/string-join.rst
  - doc_src/conf.py
  - share/functions/help.fish
tags:
  - fish-shell
  - documentation
  - conventions
---

# fish command reference pages

126 pages under `doc_src/cmds/`, one per builtin or shipped function. Each
becomes its own man page.

## Page structure

1. A title line `<cmd> - <one-line description>` underlined with `=`.
2. A `Synopsis` section containing a `.. synopsis::` block (see
   [[fish-docs-sphinx-extensions]]).
3. A `Description` section: prose, options as a bold definition list
   (`**-x**, **--long**`), plus `.. note::` and `.. versionchanged::`
   admonitions as needed.
4. An `Examples` section using `::` literal blocks with the `>_` prompt
   convention the custom lexer understands.

Commands with subcommands (`abbr`) repeat 2–4 per subcommand at H2.

There is **no** repo-wide "See also" convention — only a handful of pages use
`seealso`. It is optional, not house style.

## The title line is machine-read

`conf.py` builds Sphinx's `man_pages` list by globbing `cmds/*.rst` and regexing
each file's first line for `<name> - ` (or the double-backticked variant) to
recover the man page's `NAME` description. If it cannot find one it raises
`SphinxWarning`.[^getdesc] So the format of line 1 is not stylistic — it is
parsed, and getting it wrong fails the build.

## Transclusion for near-duplicate pages

Where one concept has several near-identical commands (`string join` and
`string join0`), the prose is written once and sliced. The source page wraps
its parts in `.. BEGIN SYNOPSIS` / `.. END SYNOPSIS` marker comments (likewise
DESCRIPTION and EXAMPLES),[^joinsrc] and consumers pull slices back in:

- the umbrella `string.rst` uses
  `.. include:: string-collect.rst` with `:start-after:`/`:end-before:`[^string]
- `string-join0.rst` includes `string-join.rst` with `:start-line: 2`, dropping
  just the title[^join0]
- `fish_title.rst` uses a different variant: the content lives wholly in
  `fish_title.inc.rst` and is pulled in with a plain `.. include::`[^title]

The `.inc.rst` suffix is load-bearing: `exclude_patterns = ["cmds/*.inc.rst"]`
keeps such files from being globbed into `man_pages` as spurious standalone
pages.[^exclude] Net effect: one prose source, but still independent
`string-join(1)` and `string-join0(1)` man pages *and* a combined `string(1)`.

## How `help` finds a page

`share/functions/help.fish` maps a topic to `cmds/$topic.html` for anything
`__fish_print_commands` reports, with hardcoded aliases (`!`→`not`, `.`→`source`,
`:`→`true`, `[`→`test`, `{`→`begin`). Non-command topics — chapter and section
names like `syntax` or `expand-command-substitution` — are validated against a
case pattern generated from `status get-file help_sections`.[^help]

It then resolves a URL, preferring a local install
(`file://$__fish_help_dir/...` when `index.html` is there) and falling back to
`https://fishshell.com/docs/$version_string/...`[^help] — so `help` degrades to
the internet copy on a docs-less install. The version string comes from the
build (see [[fish-docs-build-pipeline]]).

## share/help_sections

That lookup table is a **checked-in generated file**. It is produced by the
man build's `extract_sections` hook, then committed, then embedded into the fish
binary at compile time by `rust_embed` over `share/`,[^autoload] and read back
out through `status get-file`, which tries the embedded `Asset`, then embedded
`Docs` (man pages, present only under the `embed-manpages` cargo feature), then
the CMake binary dir.[^status]

It is not regenerated on every build. Staleness is caught by a test instead —
see [[fish-docs-conventions-and-checks]] and the general pattern in
[[checked-in-generated-artifacts]].

[^getdesc]: [`doc_src/conf.py`:216-258](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L216-L258)
[^joinsrc]: [`doc_src/cmds/string-join.rst`:7-73](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/cmds/string-join.rst#L7-L73)
[^string]: [`doc_src/cmds/string.rst`:52-60](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/cmds/string.rst#L52-L60)
[^join0]: [`doc_src/cmds/string-join0.rst`:4-5](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/cmds/string-join0.rst#L4-L5)
[^title]: [`doc_src/cmds/fish_title.rst`:4](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/cmds/fish_title.rst#L4)
[^exclude]: [`doc_src/conf.py`:151-152](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L151-L152)
[^help]: [`share/functions/help.fish`:138-197](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/share/functions/help.fish#L138-L197)
[^autoload]: [`src/autoload.rs`:41-43](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/src/autoload.rs#L41-L43)
[^status]: [`src/builtins/status.rs`:440-455](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/src/builtins/status.rs#L440-L455)
