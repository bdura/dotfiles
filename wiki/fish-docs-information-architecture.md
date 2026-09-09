---
summary: The shape of fish's manual — 15 top-level documents plus 126 command
  pages — and the fact that its table of contents and its prose recommend two
  different reading orders.
sources:
  - doc_src/index.rst
  - doc_src/tutorial.rst
tags:
  - fish-shell
  - documentation
  - information-architecture
---

# fish docs: information architecture

`doc_src/` holds roughly 6,800 lines of reStructuredText across 15 top-level
documents, plus 126 per-command pages under `doc_src/cmds/`. `language.rst`
alone is 2,179 lines; `design.rst` is 100 and carries most of the reasoning (see
[[fish-design-principles]]).

## Two orderings, one page

`index.rst` is doing two jobs at once: it is the introduction and install manual
*and* the site's table of contents. Those two roles disagree about order.

The `toctree` lists: `self, faq, interactive, language, commands,
fish_for_bash_users, tutorial, completions, prompt, design, relnotes,
terminal-compatibility, contributing, license`.[^toctree]

The prose "Where to go?" section orders by audience instead:[^whereto]

1. new users → `tutorial`
2. bash/zsh users wanting the scripting differences → `fish_for_bash_users`
3. the language reference — "If it would be useful in a script file, it's here"
4. interactive-only features — "If it's about key presses, syntax highlighting
   or anything else that needs an interactive terminal session"
5. then, for a different audience entirely (flagged as such), installation and
   configuration mechanics

That fourth-versus-third distinction is the manual's primary organising axis:
**scriptable goes in `language.rst`, terminal-only goes in `interactive.rst`**.
`CHANGELOG.rst` mirrors the same split in its per-version sections. Worth
knowing before looking something up, and worth imitating.

## The tutorial's ordering is different again

`tutorial.rst` front-loads the interactive payoff — syntax highlighting,
autosuggestions, tab completion — *before* variables, lists and expansion, and
defers startup files and autoloading to the very end as capstone topics rather
than prerequisites.[^tut] It repeatedly uses "unlike other shells" as a
deliberate marker, and says so, so the phrase is greppable.

So the tutorial and `fish_for_bash_users.rst` overlap heavily in content but
differ in framing: linear teaching narrative versus flat difference list. See
[[fish-posix-divergences]].

## Audience-specific content hiding in index.rst

Not obvious from the title: a warning that fish "may not be suitable as a login
shell" where the system needs a Bourne-compatible `/etc/profile`-reading
login shell;[^login] the recommendation of `#!/usr/bin/env fish` for portable
shebangs;[^shebang] and the split between `conf.d/*.fish` (auto-run, sorted) and
`config.fish`.[^conf]

## Documents with a non-user audience

- `terminal-compatibility.rst` targets terminal emulator authors — see
  [[fish-terminal-handling]].
- `contributing.rst` is a one-line include of the top-level `CONTRIBUTING.rst`.
- `relnotes.rst` is a one-line include of the top-level `CHANGELOG.rst`.

[^toctree]: [`doc_src/index.rst`:159-175](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L159-L175)
[^whereto]: [`doc_src/index.rst`:21-32](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L21-L32)
[^tut]: [`doc_src/tutorial.rst`](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/tutorial.rst)
[^login]: [`doc_src/index.rst`:68-70](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L68-L70)
[^shebang]: [`doc_src/index.rst`:103-108](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L103-L108)
[^conf]: [`doc_src/index.rst`:117-125](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/index.rst#L117-L125)
