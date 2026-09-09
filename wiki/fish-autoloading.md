---
summary: Functions and completions are loaded lazily by filename when first named,
  which is how fish satisfies its own law of responsiveness — and which is why
  event handlers cannot be autoloaded.
sources:
  - doc_src/language.rst
  - doc_src/completions.rst
tags:
  - fish-shell
  - performance
  - design
---

# fish autoloading

fish does not read its function and completion libraries at startup. A function
is loaded the first time its name is invoked, by looking for
`<name>.fish` along `$fish_function_path`; completions work identically along
`$fish_complete_path`.[^lang][^comp]

Three benefits are claimed: faster startup, lower memory use, and that an edited
definition propagates to already-running shells "after a while" without a
restart.[^lang]

This is the law of responsiveness from [[fish-design-principles]] made
mechanical — startup "should minimize forks and disk I/O", and blocking is only
acceptable in response to a user-initiated action.

## The cost: event handlers cannot be lazy

An `--on-event`, `--on-variable`, `--on-signal` or `--on-job-exit` handler only
becomes active once its function has been *loaded*, because fish "cannot know
that a function is supposed to be executed when an event occurs when it hasn't
yet loaded the function".[^events] Handlers must therefore be defined or sourced
eagerly from `config.fish`. This is a genuine limit of the design, stated
plainly in the docs.

Built-in event names include `fish_prompt`, `fish_preexec`, `fish_postexec`,
`fish_exit`, `fish_cancel` and `fish_focus_in`/`fish_focus_out`.[^events]

## Lookup order

Command resolution is documented step by step: a name containing a path is tried
as a literal file; otherwise fish tries a function (already loaded, else
autoloaded), then a builtin, then an executable on `$PATH` — with a fallback to
`/bin/sh` for files lacking a `#!` line. Failing all of that it calls
`fish_command_not_found` and sets status 127.[^lookup]

See [[fish-completions]] for the full completion search path, which ends in
completions compiled into the fish binary and manpage-derived completions cached
on disk.

[^lang]: [`doc_src/language.rst`:363-390](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L363-L390)
[^comp]: [`doc_src/completions.rst`:142-156](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L142-L156)
[^events]: [`doc_src/language.rst`:2088-2143](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L2088-L2143)
[^lookup]: [`doc_src/language.rst`:1905-1936](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/language.rst#L1905-L1936)
