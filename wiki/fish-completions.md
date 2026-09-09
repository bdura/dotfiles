---
summary: How fish completions are declared with the complete builtin, the
  defaults that trip up authors, and the six-stage search path they are
  discovered through — including completions generated from man pages.
sources:
  - doc_src/completions.rst
tags:
  - fish-shell
  - completions
---

# fish completions

Completions are declared with the `complete` builtin, keyed on `-c <command>`.
Three switch flavours are distinguished: `-s` short (`-o`), `-l` GNU long
(`--foo`), and `-o` old-style single-dash long (`-shuffle`).[^switches]

## The default that surprises authors

An option's argument is **optional** by default: fish only offers it when
directly attached, as in `-ofoo` or `--foo=bar`. Passing
`--require-parameter`/`-r` is what makes fish also offer the argument after a
space.[^params] Completion scripts ported naively from bash tend to get this
wrong.

File completion is on per command unless disabled with `-f`/`--no-files`, and
can then be re-enabled for individual options with `--force-files`/`-F`.[^files]

## Conditions

`-n`/`--condition` takes an arbitrary fish script string evaluated to decide
whether a completion applies. The canonical helper is
`__fish_seen_subcommand_from`; the docs point at git's completions as the
example of writing more elaborate condition functions, and work through a fully
annotated `timedatectl` example.[^cond]

A family of `__fish_*` helpers is documented — `__fish_complete_directories`,
`__fish_complete_path`, `__fish_complete_groups`, `__fish_complete_pids`,
`__fish_complete_suffix`, `__fish_complete_users`, `__fish_print_filesystems`,
`__fish_print_hostnames`, `__fish_print_interfaces` — but explicitly marked
unstable: "Such functions are internal to fish and their name and interface may
change in future fish versions."[^helpers]

## Discovery

Completions autoload exactly like functions (see [[fish-autoloading]]), keyed on
`$fish_complete_path` with the filename `<command>.fish`. The search order
is:[^path]

1. `~/.config/fish/completions` — the user's own
2. `/etc/fish/completions` — the sysadmin's
3. `~/.local/share/fish/vendor_completions.d` — user vendor
4. `/usr/share/fish/vendor_completions.d` — system vendor
5. completions compiled into the fish binary itself, listable with
   `status list-files`
6. completions **auto-generated from the system's manual pages**, cached in
   `~/.cache/fish/generated_completions`

Stage 5 is the same `rust_embed`-over-`share/` mechanism that carries
`share/help_sections`; see [[fish-command-reference-pages]].

Stage 6 is the most distinctive item and the least documented: the docs mention
it in a single line and never explain how generation works. The generator lives
under `share/tools/` and was not read in this pass — **needs verification** if a
page about it is wanted.

[^switches]: [`doc_src/completions.rst`:13-19](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L13-L19)
[^params]: [`doc_src/completions.rst`:26-39](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L26-L39)
[^files]: [`doc_src/completions.rst`:41-58](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L41-L58)
[^cond]: [`doc_src/completions.rst`:45-115](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L45-L115)
[^helpers]: [`doc_src/completions.rst`:120](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L120)
[^path]: [`doc_src/completions.rst`:142-156](https://github.com/fish-shell/fish-shell/blob/79f79059dbd9f5071b98418509fd72d59503aafb/doc_src/completions.rst#L142-L156)
