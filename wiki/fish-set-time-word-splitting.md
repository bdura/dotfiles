---
summary: fish splits variables into list elements when they are set, not when they
  are used — the single most consequential divergence from POSIX shells, and the
  reason fish scripts rarely need defensive quoting.
sources:
  - doc_src/language.rst
  - doc_src/fish_for_bash_users.rst
tags:
  - fish-shell
  - shell-semantics
  - posix
---

# Set-time word splitting

Every fish variable is a list, and "they are split into elements when they are
*set*".[^lang] POSIX shells do the opposite — they perform word splitting when a
variable is *used*, which the documentation names as "the cause of very common
problems with filenames with spaces in bash scripts".[^lang]

## What follows from it

Double-quoting a variable expansion is not the necessity it is in bash: "Once a
variable has been set to a value, that value stays as it is, so double-quoting
variable expansions isn't the necessity it is in bash."[^bash] Quoting still
matters, but for a different question — how many elements the expansion produces
when re-used — not for preventing accidental re-splitting.

Command substitution follows the same discipline: it splits on newlines only and
never on `$IFS`.[^cmdsub]

## Related

Because the mechanism is "list of elements, decided at assignment", the
indexing rules matter more than in bash. fish uses 1-based indices, justified on
ergonomic grounds — "it requires less subtracting of 1 and many common Unix
tools like `seq` work better with it" — with negative indices counting from the
end and out-of-range indices yielding no argument at all rather than an empty
string.[^index]

Variables whose names end in `PATH` are the one concession to the Unix
environment: they are treated as colon-delimited on import and export while
behaving as ordinary lists internally, because "Unix doesn't have variables with
multiple elements, the closest thing it has are colon-lists".[^pathvar]

See [[fish-variable-scopes]] for where a variable lives, and
[[fish-posix-divergences]] for the wider catalogue.

[^lang]: [`doc_src/language.rst`:697-721](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L697-L721)
[^bash]: [`doc_src/fish_for_bash_users.rst`:44](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L44)
[^cmdsub]: [`doc_src/language.rst`:827](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L827)
[^index]: [`doc_src/language.rst`:1367](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1367)
[^pathvar]: [`doc_src/language.rst`:1507-1537](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1507-L1537)
