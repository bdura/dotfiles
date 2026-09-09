---
summary: A documentation pattern — rather than reimplementing a tool's behaviour
  inside the docs build, invoke the real tool, so the docs cannot drift from the
  product.
tags:
  - documentation
  - patterns
---

# Docs driven by production tools

A general pattern, worth naming because the alternative is so tempting.

When documentation needs to reproduce some behaviour of the thing it documents —
syntax highlighting, formatting, output samples, CLI help text — you can either
reimplement that behaviour inside the docs toolchain, or shell out to the real
implementation at build time.

Reimplementing is easier to set up and guaranteed to rot: you now maintain two
descriptions of one behaviour, and only one of them is exercised by users.

Invoking the production tool trades that for a build dependency. The docs build
now needs the product built first, which complicates the pipeline and can mean
bootstrapping (build tool → build docs → package both).

## Deciding factors

- How often the behaviour changes. Stable output formats make reimplementation
  survivable; an evolving grammar does not.
- Whether drift is *visible*. Silently wrong highlighting in docs is worse than
  a build failure.
- Whether the tool can be built cheaply and reproducibly at docs time.

## Instances

- fish's docs highlight fish code by shelling out to `fish_indent --pygments`
  from a custom Pygments lexer, so the manual's highlighting is by construction
  the shell's own. The cost is that building HTML docs requires first building
  `fish_indent` and putting it on `PATH`. See
  [[fish-docs-sphinx-extensions]] and [[fish-docs-build-pipeline]].
- [[git-spice]] generates its entire CLI reference by introspecting the live
  command-parser model **in-process**, rather than by scraping `--help` output.
  A hidden `dumpmd` subcommand, compiled only under a build tag so it never
  ships, walks the parser's own tree and emits Markdown. Going in-process rather
  than shelling out gets structure that text scraping loses — flag groups, env
  var bindings, negatability — but couples doc presentation to the parser's
  struct tags, which now carry two meanings at once.

  It also inverts the pattern into a *completeness* check: the generator emits
  links like `/cli/config.md#spicefoobar` for each configurable flag, and the
  site builds with strict anchor validation, so tagging a new flag without
  writing its prose section fails the build. Link checking as a contract on
  documentation coverage, with no bespoke tooling. (Recorded from a toolchain
  exploration whose own pages were not written; see the edges note on
  [[git-spice]].)
