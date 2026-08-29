# Feature name

Short description of the feature.

Spec: [`../../specs/<feature-slug>.md`](../../specs/<feature-slug>.md).
Design record, cited by section from the task files:
[`design.md`](design.md). Shared background every task needs:
[`context.md`](context.md).

Target: branch `<branch-name>`, off `main` at `<sha>`.

## Definition of done

- [ ] High-level elements that should be verified for this feature to be considered
  done. Only tick one once you have actually run what it asks for.

## Task list

- [ ] [`<NN>-<task-slug>.md`]: short description of each task making up this plan.

## Shape of the dependency graph

```text
01 probe ─┬─> 03 trait ─> 04 host ─┬─> 05 kernel ─> 06 periodic
02 prefac ┘                        └─> 07 primitives ─> 08 suite
```

A line or two on what the graph implies: which tasks can start immediately, and
which branches can proceed in parallel.
