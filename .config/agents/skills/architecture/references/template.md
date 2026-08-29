# Architecture

One paragraph: what this project is, and the single thing it optimises for.
A reader who stops here should still know whether this is the repo they want.

## Glossary

The domain terms a newcomer will meet in the code, defined once so the rest of
the document can use them freely.

- **Term** — what it means in this project, which is not always what it means
  elsewhere.

## Bird's Eye View

What the system does, at the altitude where the whole thing fits in a few paragraphs.
Name the major components and how work flows between them. Say what the system
deliberately does *not* do — the boundaries are as informative as the contents.

## Entry Point

Where execution begins, and what happens on the way to the first interesting line:
which file, which function, what it reads, what it constructs.

## Code Map

A simplified tree, then a short section per component that needs more than its
comment.

Annotate what an entry is *for*, and where useful what it must not do. Skip
anything whose name already says everything (`.gitignore`, lockfiles, `target/`),
and collapse directories that are uniform — one line for `tests/` beats forty.

```text
├── src/
│   ├── parse/          # Text in, syntax tree out. Knows nothing about evaluation.
│   ├── eval/           # Walks the tree. The only place effects happen.
│   │   └── builtins/   # One file per builtin, registered in the module root
│   ├── config.rs       # Every tunable, resolved once at startup and then read-only
│   └── main.rs         # Argument parsing and wiring; carries no logic of its own
├── tests/              # Integration tests, one file per scenario
├── examples/           # Runnable examples; CI compiles them, so they cannot rot
└── ARCHITECTURE.md     # This document
```

### Component name

Anything the tree comment could not carry: the invariant this component holds,
what talks to it, why it is separate from its neighbour.

## Common tasks

Where to start for the changes people actually make — "add a builtin", "support
a new backend", "add a config option". A pointer per task, not a tutorial.

## Cross-cutting concerns

The things that do not live in one module: error handling, logging, invariants
that span components, the rules that any change has to respect. Where an invariant
is enforced, say by what — a type, a test, or only a convention.
