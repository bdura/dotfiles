---
summary: The catalogue of things fish deliberately does not have or does
  differently from POSIX shells, each traced back to the design law that
  generates it.
sources:
  - doc_src/fish_for_bash_users.rst
  - doc_src/language.rst
  - doc_src/faq.rst
tags:
  - fish-shell
  - posix
  - shell-semantics
---

# fish's deliberate POSIX divergences

"fish is intentionally not POSIX-compatible."[^stance] `fish_for_bash_users.rst`
is organised as a flat difference list; the same ground is covered narratively in
the tutorial, which uses the phrase "unlike other shells" as a deliberate
rhetorical marker readers can grep for.[^tutorial] Almost every entry below is
an instance of a law in [[fish-design-principles]].

## Absent by orthogonality

- **No heredocs.** The argument: "heredocs really are minor syntactical sugar
  that introduces a lot of special rules, which is why fish doesn't have them.
  Pipes are a core concept, and are simpler and compose nicer."[^heredoc]
  Use `printf`, a quoted `echo`, or a pipe.
- **No subshells.** "fish does not currently have subshells. You will have to
  find a different solution."[^subshell] Isolation is achieved with `set -l`
  scoping, or an explicit `fish -c '...'` when a separate process is genuinely
  needed. `()` is command substitution, not subshelling; `begin`/`end` groups
  without forking. Note the hedge "currently" — this reads as an acknowledged
  gap rather than the settled principle `design.rst` presents it as.
- **No process substitution `>(...)`.** `psub` covers the read side.
- **No separate alias facility.** `alias` defines a function; "fish functions
  have none of the drawbacks of either syntax".[^ortho]
- **No history substitution (`!!`).** Rejected with a reason: "Because history
  substitution is an awkward interface that was invented before interactive line
  editing was even possible. Instead of adding this pseudo-syntax, fish opts for
  nice history searching and recall features."[^bang] The docs then hand back the
  common case (`alt-s` for `sudo !!`) and show an `abbr --function` recipe for
  anyone who wants `!!` anyway.
- **No backticks.** "Backticks are not supported because they are discouraged
  even in POSIX shells. They nest poorly and are hard to tell from single
  quotes."[^backtick]
- **No `$''` quoting style**, and no `${var:-default}` — use `set -q`.

## Different by design

- **Word splitting at set time, not use time** — see
  [[fish-set-time-word-splitting]]. The most consequential difference.
- **No `then`, no `do`.** An `if` condition is a literal command and ends after
  the first job: "Unlike other shells, the condition command ends after the first
  job, there is no `then` here."[^ifthen] Every block ends in `end`; there is no
  `until`.
- **`switch` has no fallthrough** — the first matching `case` runs and control
  jumps out.[^switch]
- **`and`/`or` combine step by step**, not as a short-circuit tree. The docs
  give a worked example of a chain silently doing the wrong thing and recommend
  `if` for anything past two terms.[^combiners]
- **No arithmetic expansion.** `math` replaces `$((...))` and handles floats and
  trigonometry, which bash's integer arithmetic cannot; multiplication needs
  quoting or the `x` operator because `*` looks like a glob.[^math]
- **No `[[`** — `test`/`[` only.
- **Unmatched wildcards are an error**, roughly bash's `failglob`, with no option
  to change it. This gets the FAQ's longest and most careful argument, including
  a comparison to bash's own `BashFAQ/004` workaround pattern.[^glob]
- **`string` replaces the `${foo%bar}` family** of parameter-expansion
  operators with a real command.
- **Prompts are functions whose output is used**, not `$PS1` with `\h`/`\w`
  escapes — the interactive-side instance of "one kind of input: commands". See
  [[fish-interactive-features]].

## The variable translation table

`fish_for_bash_users.rst` supplies the mapping directly: `$*`/`$@`/`$1` →
`$argv`, `$?` → `$status`, `$$` → `$fish_pid`, `$#` → `count $argv`, `$!` →
`$last_pid`, `$0` → `status filename`, `$-` → `status is-interactive` /
`is-login`. `VAR=VAL`, `declare`, `unset` and `export` all collapse into `set`.

## Status codes beyond POSIX convention

fish assigns specific meanings above the usual range: 121 invalid arguments,
122 command-substitution or `read` data limit exceeded, 123 invalid characters
in a command name, 124 wildcard matched nothing, 125 exec failed at OS level,
126 not executable, 127 not found, and 128+signal for death by
signal.[^status] `$pipestatus` holds the per-stage list and is deliberately
*not* affected by `not` — negating a whole pipeline's per-stage list "loses
information"; only `$status` is negated.[^pipestatus]

The docs also call the `pipefail` feature of other shells "a big problem"
without much further argument.[^pipefail] Flagged as a thin claim.

## One admitted own goal

`config.fish` always runs, interactive or not, which the FAQ defends as
simplicity — "This simplifies matters" — while conceding it can break SSH, SCP
and rsync when `config.fish` produces output on a non-interactive connection,
requiring `status is-interactive` guards.[^configfish] A rare case of the
documentation naming the cost of a design choice without walking it back.

[^stance]: [`doc_src/fish_for_bash_users.rst`:4](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L4)
[^tutorial]: [`doc_src/tutorial.rst`](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/tutorial.rst), "Learning fish"
[^heredoc]: [`doc_src/fish_for_bash_users.rst`:276](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L276)
[^subshell]: [`doc_src/fish_for_bash_users.rst`:414-450](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L414-L450)
[^ortho]: [`doc_src/design.rst`:15-31](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/design.rst#L15-L31)
[^bang]: [`doc_src/faq.rst`:159-161](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L159-L161)
[^backtick]: [`doc_src/faq.rst`:190](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L190)
[^ifthen]: [`doc_src/language.rst`:435](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L435)
[^switch]: [`doc_src/language.rst`:493](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L493)
[^combiners]: [`doc_src/language.rst`:509-542](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L509-L542)
[^math]: [`doc_src/fish_for_bash_users.rst`:291-312](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/fish_for_bash_users.rst#L291-L312)
[^glob]: [`doc_src/faq.rst`:249-296](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L249-L296)
[^status]: [`doc_src/language.rst`:1781-1799](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1781-L1799)
[^pipestatus]: [`doc_src/language.rst`:1803](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1803)
[^pipefail]: [`doc_src/language.rst`:1829](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1829)
[^configfish]: [`doc_src/faq.rst`:298-317](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/faq.rst#L298-L317)
