---
summary: fish's two custom Sphinx extensions — a Pygments lexer that delegates to
  the real fish_indent binary, and a synopsis directive that renders differently
  per output format.
sources:
  - doc_src/fish_indent_lexer.py
  - doc_src/fish_synopsis.py
  - doc_src/conf.py
tags:
  - fish-shell
  - documentation
  - sphinx
---

# fish's Sphinx extensions

Two extensions, both small, both solving a problem plain Sphinx cannot.

## fish_indent_lexer.py — highlighting by delegation

Registered as the `fish` and `fish-docs-samples` lexers, the latter being the
default `highlight_language`.[^conf-hl] It does not reimplement fish's grammar
in Python. It shells out to `fish_indent --pygments`, which emits
`start,end,role` triples, and maps fish's own role names (`command`, `keyword`,
`param`, `quote`, …) onto Pygments token types.[^lexer]

Two consequences:

- The docs' highlighting cannot drift from the shell's, because it *is* the
  shell's. This is [[docs-driven-by-production-tools]].
- Building HTML docs now requires a working `fish_indent` on `PATH`, which is
  why `cargo xtask html-docs` builds and symlinks one first — see
  [[fish-docs-build-pipeline]].

It also implements a transcript convention: lines beginning `>` or `>_` are
tokenised as fish code with the prompt marked `Generic.Prompt`, and every other
line is treated as command *output* (`Generic.Output`).[^lexer-prompt] Authors
can paste a realistic interactive session into a code block and get input and
output visually distinguished for free.

For the `man` and `markdown` builders the lexer is deliberately removed, since
neither can carry colour and it would only cost `fish_indent`
subprocesses.[^conf-remove]

## fish_synopsis.py — one directive, two renderings

`.. synopsis::` appears on essentially every page in `doc_src/cmds/`. The
problem it solves is that a synopsis needs genuinely different typography per
output format, and Sphinx's man writer cannot be driven by Pygments.

- **HTML**: delegates to the standard `CodeBlock` directive with a custom
  `fish-synopsis` lexer, so literal tokens, placeholders and grammar
  metacharacters (`[`, `]`, `|`, `...`) get distinct colours.[^syn]
- **man**: hand-tokenises the content and emits a `docutils` `line_block` in
  which literals become `nodes.strong` and uppercase placeholders become
  `nodes.emphasis`[^syn] — reimplementing by hand the conventional man-page
  typography of **bold** for literal and *italic* for placeholder.

`FishSynopsisLexer` is grammar-aware rather than a flat regex list: it tracks
`is_before_command_token` so a bareword at a rule boundary — line start, after
`;`, after `and`/`or`/`not`/`time` — is a command name (`Name.Function`, bold)
while a bareword elsewhere is a parameter (`Name.Constant`).[^syn-lexer]

Two honest hacks are worth knowing about, both commented as such:

- the closing bracket of the `test`/`[` alias is special-cased as a literal
  ("Tiny hack: the closing bracket of the test(1) alias is a literal")[^syn]
- multi-line synopses are split into one "rule" per non-indented line, except
  that `end` always joins the preceding rule, so block syntaxes like
  `switch`/`case`/`end` group correctly. The docstring concedes this is a
  heuristic — "this is enough in practice" — not a parser.[^syn-lexer]

## A third mechanism in conf.py

`extract_sections`, hooked to Sphinx's `env-updated` event and active for the
man builder only, walks the generated table of contents and writes every
`docname#anchor` pair to the file named by the `fish_help_sections_output`
config value — skipping generated `#idN` anchors, anchors inside `cmds/*`, and
`relnotes` — asserting each matches `[\w-]`.[^extract] Its output is
`share/help_sections`, the lookup table the `help` builtin validates topics
against. See [[fish-command-reference-pages]] and
[[checked-in-generated-artifacts]].

[^conf-hl]: [`doc_src/conf.py`:111](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L111)
[^lexer]: [`doc_src/fish_indent_lexer.py`:28-99](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_indent_lexer.py#L28-L99)
[^lexer-prompt]: [`doc_src/fish_indent_lexer.py`:107-130](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_indent_lexer.py#L107-L130)
[^conf-remove]: [`doc_src/conf.py`:80-106](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L80-L106)
[^syn]: [`doc_src/fish_synopsis.py`:25-56](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_synopsis.py#L25-L56)
[^syn-lexer]: [`doc_src/fish_synopsis.py`:90-140](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_synopsis.py#L90-L140)
[^extract]: [`doc_src/conf.py`:49-77](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/conf.py#L49-L77)
