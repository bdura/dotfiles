---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that
loop produce tests worth keeping: what a good test is, where tests go, the
anti-patterns, and the rules of the loop. Every section applies on every cycle:
consult them before and during the loop, not after.

## What a good test is

Tests verify behavior to build confidence in each building blocks that make the
codebase.

Tests should assert invariants and check common cases.

When possible, make use of property testing to dramatically increase a test's reach.
Prop-testing can also prove useful for functions for which tests are harder to
design, by checking an invariant rather than an actual result. For instance,
testing that a point is to the left or right of an arc is hard, while checking
whether a point is inside a circle is easy. Checking that two arcs making up a
full circle agree tests the former through the latter.

A good test maximizes reach while minimizing runtime, in order to build as much
confidence as possible without hindering velocity: keep tests fast.

## Where tests go

Every function should be tested.

- Lower-level functions should be tested thoroughly to make sure the codebase
  rests on solid grounds.
- Public interfaces should get a particular focus, since they are more stable
  than implementation details. Code can change entirely; tests shouldn't.

Before writing any test, write down what will be tested and confirm with the user.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, or verifies through a
  side channel. The tell: the test breaks when you refactor but behavior hasn't
  changed.
- **Tautological**: the assertion recomputes the expected value the way the code
  does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way,
  a constant asserted equal to itself), so it passes by construction and can
  never disagree with the code. Expected values must come from an independent
  source of truth: a known-good literal, a worked example, the spec.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to
  pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.**
