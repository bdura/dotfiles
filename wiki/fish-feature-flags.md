---
summary: fish's mechanism for shipping breaking language changes — opt-in, then
  opt-out, then removed — with each flag documented against the versions where it
  changed state.
sources:
  - doc_src/language.rst
tags:
  - fish-shell
  - versioning
  - design
---

# fish feature flags

A shell script has no way to pin the language version it was written against, so
fish carries an explicit staging mechanism for incompatible changes. Each change
gets a named flag that moves through three states: opt-in, then default-on but
opt-out, then removed as a flag with the new behaviour permanent.[^flags]

The documentation lists flags with the versions at which they changed state —
`qmark-noglob`, for instance, was available from 3.0 and became the default in
4.0.[^flags]

This is fish's answer to a problem every long-lived language faces, and it is a
pattern worth comparing against other projects' deprecation processes. It also
appears operationally elsewhere: [[fish-terminal-handling]] uses the
`query-terminal` flag to let users disable the startup terminal probe.

For the changes themselves and their user-facing framing, `CHANGELOG.rst` is
the primary source, organised per version into "Interactive improvements",
"Scripting improvements" and "Regression fixes" — the last tagged with the
version each regression came from. Its interactive/scripting split mirrors the
`interactive.rst`/`language.rst` split in the manual itself (see
[[fish-docs-information-architecture]]).

[^flags]: [`doc_src/language.rst`:2033-2087](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L2033-L2087)
