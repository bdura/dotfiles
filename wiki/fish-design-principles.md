---
summary: fish's three high-level goals and five named design laws, the concrete
  feature-absences each one generates, and the tension between the
  anti-configuration law and fish's many tunables.
sources:
  - doc_src/design.rst
tags:
  - fish-shell
  - design
  - shell
---

# fish design principles

`doc_src/design.rst` is 100 lines long and does more work than any other file in
the repository: it is the stated cause of most of fish's concrete divergences
from other shells. See [[fish-posix-divergences]] for the effects.

## Three goals, in priority order

1. "Everything that can be done in other shell languages should be possible to
   do in fish, though fish may rely on external commands in doing so."[^goals]
   Completeness by composition, not by native reimplementation of every POSIX
   mechanism.
2. "fish should be user-friendly, but not at the expense of expressiveness. Most
   tradeoffs between power and ease of use can be avoided with careful
   design."[^goals] This explicitly rejects the premise that usability and power
   trade off; an apparent tradeoff is treated as a design failure to be solved.
3. "Whenever possible without breaking the above goals, fish should follow
   POSIX."[^goals]

The ordering is the point: POSIX compliance is subordinate, which is why
`fish_for_bash_users.rst` can open with "fish is intentionally not
POSIX-compatible".[^notposix]

## The law of orthogonality

Related-but-not-identical features should collapse into one general feature.
The reason given is twofold — "Related features make the language larger, which
makes it harder to learn. It also increases the size of the source code, making
the program harder to maintain and update."[^ortho]

Consequences the document itself claims: no heredocs (too close to echoing into
a pipeline), no separate subshell or process-substitution mechanism (only
command substitution, with `psub` as the escape hatch), no alias facility
distinct from functions, and a rejection of POSIX's several quoting styles
("The many Posix quoting styles are silly, especially \$").[^ortho]

## The law of responsiveness

"The shell should attempt to remain responsive to the user at all times, even in
the face of contended or unresponsive filesystems. It is only acceptable to
block in response to a user initiated action."[^resp] The rationale is
behavioural rather than aesthetic: "Bad performance increases user-facing
complexity, because it trains users to recognize and route around slow use
cases."[^resp]

Two engineering commitments follow: highlighting and autosuggestions must do all
disk I/O asynchronously, and startup must minimise forks and disk I/O.[^resp]
This is the direct cause of [[fish-autoloading]].

## Configurability is the root of all evil

The strongest claim in the repository: "Every configuration option in a program
is a place where the program is too stupid to figure out for itself what the
user really wants, and should be considered a failure of both the program and the
programmer who implemented it."[^config] Options are argued to be a
combinatorial bug surface, to encode assumptions that break under
reimplementation, and to be unnecessary where the program could simply decide.

The document also attacks the inverse failure: zsh and bash are criticised for
shipping command-specific completion, wildcard tab completion, a usable
completion pager and a history file, and then *disabling them by
default*.[^config] fish's stance is that such features should be on or not exist
as toggles — which is what "no configuration needed" in the introduction cashes
out to.

**The document's own admitted exception** is syntax-highlighting colours. It
concedes these are a workaround and states what the real fix would be: "the
proper solution would be for text color preferences to be defined centrally by
the user for all programs, and for the terminal emulator to send these color
properties to fish".[^config] That gap has since been partly closed by
`fish_terminal_color_theme`, which queries the terminal for its light/dark
theme.[^colortheme]

**An unresolved tension worth carrying forward.** The law is reconciled only
for colours, yet `language.rst` and `interactive.rst` enumerate dozens of other
tunables — `fish_escape_delay_ms`, `fish_sequence_key_delay_ms`,
`fish_ambiguous_width`, `fish_cursor_selection_mode` — which exist for
essentially the same reason (fish cannot infer terminal and keyboard behaviour)
but are never squared with the law in the documentation as read. See
[[fish-terminal-handling]]. This is a gap in the docs' argument, not a
contradiction between two sources.

## The law of user focus

Alone among the five, this is a *process* rule about how to design, not a
constraint on what to build: design the interface first, the implementation
second. "The problem with focusing on what can be done, and what is easy to do,
is that too much of the implementation is exposed", which forces users to
understand internals to predict behaviour.[^focus]

Four consequences are claimed, and the third is a substantial architectural
claim that is easy to miss:

- The shell has exactly one kind of input, "lists of commands" — loops,
  conditionals and assignment are ordinary commands, not special syntax.[^focus]
- Builtins and functions should be indistinguishable in use: same expansion,
  redirection and pipeline rules.[^focus]
- fish avoids the fork-per-command-substitution trick other shells use to fake
  scoping; "instead ... all fish commands are performed from the same process,
  and fish instead supports true scoping".[^focus] Single-process execution is
  presented as a *user-interface* decision, not a performance one. See
  [[fish-variable-scopes]].
- Uniform block termination: "All blocks end with the `end` built-in."[^focus]

## The law of discoverability

Features should be findable without leaving the shell. The reasoning is a
comparison with GUIs: "The main benefit of a graphical program over a
command-line-based program is discoverability ... The traditional way to discover
features in command-line programs is through manual pages. This requires both
that the user starts to use a different program, and then they remember the new
information."[^disco]

Consequences: tab completion with descriptions everywhere; errors that explain
themselves, point at a help page, and are flagged red by the highlighter; and a
complete, example-rich manual reachable from inside the shell — which is why the
`help` builtin and the man-page build are load-bearing rather than incidental
(see [[fish-command-reference-pages]]). The distinctive claim is that
"The language should be uniform, so that once the user understands the
command/argument syntax, they will know the whole language, and be able to use
tab-completion to discover new features"[^disco] — tab completion framed as a
language-discovery mechanism rather than a typing shortcut.

## How to read the argument

The document is principle-first and example-second: the examples (heredocs,
subshells, aliases) are asserted to follow obviously from a law rather than
argued independently. If you want an independently argued case, the FAQ's
defence of wildcard-no-match erroring is the closest thing in the repo.[^faqglob]

[^goals]: [`doc_src/design.rst`:4-11](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L4-L11)
[^ortho]: [`doc_src/design.rst`:15-31](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L15-L31)
[^resp]: [`doc_src/design.rst`:34-46](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L34-L46)
[^config]: [`doc_src/design.rst`:48-62](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L48-L62)
[^focus]: [`doc_src/design.rst`:64-80](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L64-L80)
[^disco]: [`doc_src/design.rst`:82-100](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L82-L100)
[^notposix]: [`doc_src/fish_for_bash_users.rst`:4](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L4)
[^colortheme]: [`doc_src/language.rst`:1707-1714](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1707-L1714)
[^faqglob]: [`doc_src/faq.rst`:249-296](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L249-L296)
