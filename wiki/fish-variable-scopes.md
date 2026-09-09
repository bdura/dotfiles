---
summary: fish's four variable scopes — universal, global, function, local — plus
  export as an orthogonal state, and why true scoping is possible at all.
sources:
  - doc_src/language.rst
  - doc_src/faq.rst
  - doc_src/prompt.rst
tags:
  - fish-shell
  - shell-semantics
---

# fish variable scopes

Four kinds, inside-out in lookup order local → function → global →
universal:[^scopes]

- **local** — block-scoped, dying at the `end` of the enclosing `for`, `while`,
  `if`, `function`, `begin` or `switch`.
- **function** — lives until the function returns. Distinct from local: it is
  *not* block-scoped.
- **global** — lives for the session.
- **universal** — persisted to disk in `~/.config/fish/fish_variables`, shared
  across all of the machine's sessions, and never to be hand-edited.

A function called from another function does not see the caller's locals;
`language.rst` gives a worked example.[^nesting]

## Export is a state, not a scope

The docs make this point in nearly identical words in three separate
files,[^exported1][^exported2] which is a good signal that it is a common
confusion. A variable is exported *and* has a scope; the two are independent.

The FAQ documents the trap this creates: a universal exported variable can be
silently shadowed by an inherited global environment variable of the same name,
because lookup runs inside-out and global beats universal.[^faqscope]

## Why fish can have real scoping

Other shells fake scoping by forking for command substitution. fish does not:
"all fish commands are performed from the same process, and fish instead
supports true scoping."[^design] The single-process architecture is presented in
[[fish-design-principles]] as a consequence of the law of user focus — a
user-interface decision, not a performance one. It is also why fish has no
subshells at all (see [[fish-posix-divergences]]).

## In practice

Guidance elsewhere in the docs leans on this taxonomy constantly. Prompt
functions should capture `$status` into a *local* variable as their very first
statement, since every subsequent command overwrites it, and keep their working
state confined to the function.[^prompt]

[^scopes]: [`doc_src/language.rst`:1152-1281](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1152-L1281)
[^nesting]: [`doc_src/language.rst`:1262-1278](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1262-L1278)
[^exported1]: [`doc_src/language.rst`:1348](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1348)
[^exported2]: [`doc_src/faq.rst`:21](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L21)
[^faqscope]: [`doc_src/faq.rst`:54-70](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L54-L70)
[^design]: [`doc_src/design.rst`:64-80](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L64-L80)
[^prompt]: [`doc_src/prompt.rst`:115](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/prompt.rst#L115)
