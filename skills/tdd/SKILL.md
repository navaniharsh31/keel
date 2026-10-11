---
name: tdd
description: Test-driven development, one red-green slice at a time at pre-agreed seams. Use when building a feature or fixing a bug test-first, or when writing tests.
---

# Test-Driven Development

TDD is the red → green loop. This skill is the reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle: consult them before and during the loop, not after.

## What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure. Name tests in the glossary's terms.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** In a keel flow they are already agreed: the spec's Testing Decisions (approved at G2), the seams settled while grilling (inline mode), or, from keel:debug, the seam Phase 5 judged correct. Used standalone, write down the seams under test and confirm them with the user before writing any test. Give each proposed seam a one-line note on what it catches and what it misses. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

## Design vocabulary

- **Module**: anything with an interface and an implementation, at any scale (function, class, package, tier-spanning slice).
- **Interface**: everything a caller must know to use the module: types, invariants, ordering, error modes, required config, performance.
- **Depth**: behaviour a caller (or test) can exercise per unit of interface learned. **Deep** is a lot of behaviour behind a small interface; **shallow** is an interface nearly as complex as its implementation.
- **Seam**: the location where a module's interface lives, where behaviour can change without editing in that place.
- **Adapter**: a concrete thing that satisfies an interface at a seam.

Principles:

- **The deletion test.** Imagine deleting the module. If complexity vanishes, it was a pass-through; if it reappears across callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Introduce a seam only where something actually varies across it.
- **Accept dependencies, return results.** Pass collaborators in; return values instead of producing side effects.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, watch it fail for the reason you expect, then write only enough code to pass it. Build only what the current test demands.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring belongs to review.** The red → green cycle ends at green; keel:review finds the refactors.
- **Mock only at system boundaries** (external APIs, time, randomness), per [mocking.md](mocking.md).

## Done

- [ ] Every acceptance criterion in the ticket (or line of the G1 summary, or the bug's symptom) has a test at an agreed seam that went red, then green.
- [ ] The full suite is green.
