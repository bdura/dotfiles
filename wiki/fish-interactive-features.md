---
summary: Autosuggestions, syntax highlighting, the completion pager,
  abbreviations, key bindings, history search and private mode — what
  interactive.rst documents and the rationale it gives.
sources:
  - doc_src/interactive.rst
  - doc_src/prompt.rst
tags:
  - fish-shell
  - interactive
  - ux
---

# fish interactive features

"fish prides itself on being really nice to use interactively."[^open] These are
the features that live only in a terminal session; anything usable in a script
file is in `language.rst` instead. That split is deliberate and structural — see
[[fish-docs-information-architecture]].

## Autosuggestions

A greyed-out inline suggestion drawn from history, completions and valid file
paths. Accept the whole thing with right-arrow or `ctrl-f`, one word with
`alt-right` or `alt-f`; it "won't execute unless you accept it".[^autosugg]
Pitched as both a recall mechanism and "an efficient technique for navigating
through directory hierarchies". The requirement that it never block on disk I/O
comes from the law of responsiveness in [[fish-design-principles]].

## Tab completion and the pager

Tab inserts the longest unambiguous prefix, then opens a navigable pager on
ambiguity — arrows, page up/down, tab/shift-tab, and `ctrl-s` to search within
the pager.[^tab] The distinctive claim is about *depth*: fish ships program-
specific completions that go beyond listing flags, so `make` completes Makefile
targets, `mount` completes fstab entries, and package managers complete
installed and installable package names.[^tab] This is the law of
discoverability being cashed in. See [[fish-completions]] for how they are
written.

## Syntax highlighting

Live detection of non-existent commands, redirections to non-existent files,
malformed redirections and mismatched parentheses, red by default, themeable via
`fish_color_*` and `fish_pager_color_*` or `fish_config theme`.[^hl]

The docs give a neat pattern for live theme propagation: set the colour as a
universal variable and hook `--on-variable` so every open session redraws
without restarting.[^theme] Universal variables plus events is fish's general
answer to live reconfiguration; see [[fish-variable-scopes]] and
[[fish-autoloading]].

## Abbreviations

`abbr` expands on space or enter, in command position. It is explicitly
contrasted with aliases: "The advantage over aliases is that you can see the
actual command before using it, add to it or change it, and the actual command
will be stored in history."[^abbr] Regex- and function-backed abbreviations are
supported — the docs build a `..`/`...`/`....` "go up N directories"
abbreviation from `--regex` plus `--function`.[^abbr]

Note this is not a re-introduction of the alias concept that
[[fish-design-principles]] rejects: it is an editor-level expansion mechanism
that leaves the real command in the buffer and in history.

## Prompt, title and greeting

All three are ordinary functions — `fish_prompt`, `fish_right_prompt`,
`fish_mode_prompt`, `fish_title`, `fish_greeting` — whose *output* is used
verbatim.[^prompt] No `$PS1`, no `\h`/`\w` escapes. This is the law of user
focus applied to the prompt: one kind of input, commands.
`fish_transient_prompt` can redraw with `--final-rendering` before a command
runs, so scrollback keeps a decluttered prompt.[^transient]

`prompt.rst` is a worked tutorial rather than a reference, building a prompt from
`echo` through `string join`, `set_color` (explained as emitting raw escapes —
`set_color red` ≈ `echo \e\[31m`), `prompt_pwd`, conditional `$status` display
and `funcsave`. It is explicitly framed as "a good way to get used to fish's
scripting language",[^prompttut] so it doubles as a language tutorial.

## Key bindings

Two full sets: Emacs by default, vi via `fish_vi_key_bindings`. The vi support
does not claim completeness — it is "not a complete implementation", with
`alt-e` dropping into `$VISUAL`/`$EDITOR` for anything beyond it.[^bind] A large
shared-bindings section exists for keys common to both, because they "aren't
text editing bindings, or because what vi/Vim does for a particular key doesn't
make sense for a shell"[^shared] — an explicit acknowledgement that fidelity to
the editor loses to shell semantics where they conflict.

Key-sequence disambiguation (`fish_escape_delay_ms`,
`fish_sequence_key_delay_ms`) exists because legacy terminal encodings are
ambiguous — `ctrl-i` is tab, escape is alt — and fish prefers newer terminal
protocols where available.[^keyseq] See [[fish-terminal-handling]].

## History and private mode

Up/down search by substring, `alt-up`/`alt-down` by token, `ctrl-r` for a pager
search. Prefixing a command with a space keeps it out of persistent history
while leaving it available for immediate recall.[^hist] `fish --private` (`-P`)
disables persistence entirely and hides prior history, motivated by screencasts
and sensitive sessions, and exposes `$fish_private_mode` so scripts can respect
it.[^priv]

## Directory navigation

Two mechanisms, kept explicitly separate: automatic directory *history* driven
by `cd` (`dirprev`/`dirnext`, `dirh`, `cdh`, `prevd`, `nextd`), and the manual
bash-style directory *stack* (`pushd`, `popd`, `dirs`) which only ever changes
when you call it.[^dirs]

[^open]: [`doc_src/interactive.rst`:4](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L4)
[^autosugg]: [`doc_src/interactive.rst`:19-32](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L19-L32)
[^tab]: [`doc_src/interactive.rst`:36-57](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L36-L57)
[^hl]: [`doc_src/interactive.rst`:59-206](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L59-L206)
[^theme]: [`doc_src/interactive.rst`:87-99](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L87-L99)
[^abbr]: [`doc_src/interactive.rst`:220-229](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L220-L229)
[^prompt]: [`doc_src/interactive.rst`:233-296](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L233-L296)
[^transient]: [`doc_src/prompt.rst`:158-196](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/prompt.rst#L158-L196)
[^prompttut]: [`doc_src/prompt.rst`:12](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/prompt.rst#L12)
[^bind]: [`doc_src/interactive.rst`:299-317](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L299-L317)
[^shared]: [`doc_src/interactive.rst`:323](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L323)
[^keyseq]: [`doc_src/interactive.rst`:604-636](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L604-L636)
[^hist]: [`doc_src/interactive.rst`:669-698](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L669-L698)
[^priv]: [`doc_src/interactive.rst`:700-709](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L700-L709)
[^dirs]: [`doc_src/interactive.rst`:711-742](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/interactive.rst#L711-L742)
