---
name: tdd
description: Test-driven development, one red-green slice at a time at pre-agreed seams. Use when building a feature or fixing a bug test-first, or when writing tests.
---

# Test-Driven Development

The red → green loop, and the rules, on every cycle, that make it produce tests worth keeping.

## What a good test is

A good test verifies behavior through a public interface, reads like a specification ("user can checkout with valid cart"), and survives a refactor. Name tests in the glossary's terms. Never write:

- **Implementation-coupled** tests: mocking internal collaborators, testing private methods, verifying through a side channel. They break on refactors that keep behavior.
- **Tautological** tests: the expected value recomputed the way the code computes it, so it passes by construction. Take expected values from an independent source: a known-good literal, a worked example, the spec.

Read [tests.md](tests.md) when a test's shape is in doubt or a module's interface is being shaped: examples, the anti-patterns in full, the design vocabulary. Read [mocking.md](mocking.md) before you mock anything.

## Seams: where tests go

A **seam** is the public boundary you test at, where you observe behavior without reaching inside. **Test only at pre-agreed seams.** In a keel flow they are agreed: the spec's Testing Decisions (approved at G2), the seams settled while grilling (inline mode), or, from keel:debug, the seam Phase 5 judged correct. Standalone, confirm the seams with the user before any test, each with a one-line note on what it catches and misses. Agreed seams put testing effort on the critical paths, complex logic and their near-misses, not every edge case.

## Rules of the loop

- **Red before green.** Write the failing test, watch it fail for the reason you expect, then write only enough code to pass it.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle, each test a tracer bullet shaped by the last cycle. Never all tests first: bulk tests verify imagined behavior.
- **Refactoring belongs to review.** The cycle ends at green; keel:review finds the refactors.
- **Mock only at system boundaries** (external APIs, time, randomness), per mocking.md.
- **Existing tests are probes.** When an existing test starts failing or warning under the new behaviour, first decide whether it caught a real defect; if so, fix the code. Edit an existing test only when its expectation is what the work changes, and give each such edit a reason in your summary. Where the language allows, run the suite once with the new warning or error made fatal, to list every place it fires.

## Done

- [ ] Every acceptance criterion in the ticket (or line of the G1 summary, or the bug's symptom) has a test at an agreed seam that went red, then green.
- [ ] The full suite is green.
- [ ] Every edit to an existing test has a reason in the summary.
