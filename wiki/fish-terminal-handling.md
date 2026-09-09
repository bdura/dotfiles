---
summary: fish does not read the system terminfo database — it probes the terminal
  with escape sequences instead, which buys accuracy and costs a startup query
  and a documented failure mode.
sources:
  - doc_src/terminal-compatibility.rst
  - doc_src/faq.rst
tags:
  - fish-shell
  - terminal
  - design
---

# fish terminal handling

`terminal-compatibility.rst` is a protocol reference aimed at terminal emulator
authors and fish contributors rather than users: it enumerates the required and
optional CSI/OSC/DCS sequences (per ECMA-48) that fish depends on.

## The non-obvious claim

"fish does not rely on your system's terminfo database."[^noterminfo] Terminfo
capability names appear in the document "for reference only". Most shells and
terminal tools consult terminfo; fish instead queries the terminal directly, for
example with a Primary Device Attribute request (`\e[0c`).

The trade is stated: on a terminal that does not answer, the user gets "a brief
pause at startup followed by a warning", mitigable by turning off the
`query-terminal` feature flag.[^noterminfo] See [[fish-feature-flags]].

## Where the anti-configuration law runs out

The tunables fish carries for terminal and keyboard behaviour —
`fish_escape_delay_ms`, `fish_sequence_key_delay_ms`, `fish_ambiguous_width`,
`fish_cursor_selection_mode` — all exist because fish cannot infer the answer.
That is precisely the situation
[[fish-design-principles]] calls a failure of the program, and the design
document reconciles only the colour case. The tension is not addressed in the
docs as read.

The FAQ is blunt about one hard limit rather than offering an option: on
character width, "there is *no way* for fish to figure out what width a specific
character has as it has no influence on the terminal's font rendering", making
non-monospace fonts and per-character ambiguous-width preferences flatly
unsupportable.[^unicode]

This document is linked from the FAQ's "fish does not work in a specific
terminal" entry, which is its main entry point for users.

[^noterminfo]: [`doc_src/terminal-compatibility.rst`:17](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/terminal-compatibility.rst#L17)
[^unicode]: [`doc_src/faq.rst`:334-337](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L334-L337)
