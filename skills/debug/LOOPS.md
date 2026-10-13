# Building the feedback loop

Reference for Phase 1 of [SKILL.md](SKILL.md), read when a failing test isn't a tight loop at once.

## Ways to construct one, in order of preference

1. **Failing test** at whatever seam reaches the bug: unit, integration, e2e.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) that drives the UI and asserts on DOM, console or network.
5. **Replay a captured trace**: a saved request, payload or event log, replayed through the code path in isolation.
6. **Throwaway harness**: a minimal subset of the system (one service, mocked deps) that reaches the bug path in one call.
7. **Property / fuzz loop**: for "sometimes wrong output", run 1000 random inputs and look for the failure.
8. **Bisection harness**: when the bug appeared between two known states (commit, dataset, version), automate the check so `git bisect run` drives it.
9. **Differential loop**: the same input through the old and new version (or two configs), outputs diffed.
10. **HITL script**: last resort. If a human must click, drive _them_ with `hitl-loop.template.sh`, so the loop stays structured and its output comes back to you.

## Tighten the loop

Once you have _a_ loop, make it faster (cache setup, skip unrelated init, narrow the scope), sharper (assert the specific symptom, not "didn't crash") and deterministic (pin time, seed RNG, isolate the filesystem, freeze the network). A 30-second flaky loop is barely better than none; a 2-second deterministic one is tight.

## Non-deterministic bugs

Aim for a **higher reproduction rate**, not a clean repro: loop the trigger 100×, parallelise, add stress, narrow timing windows, inject sleeps. A 50% flake is debuggable and 1% is not, so keep raising the rate.

## When you cannot build a loop

Stop and say so, listing what you tried. Ask the user for (a) access to an environment that reproduces it, (b) a redacted captured artifact (HAR file, log dump, core dump, timestamped screen recording), or (c) permission to add temporary production instrumentation. Do **not** hypothesise without a loop.

## Instrumenting

Reference for Phase 4 of [SKILL.md](SKILL.md). Prefer a debugger or REPL where the environment has one (one breakpoint beats ten logs), then targeted logs at the boundaries that tell hypotheses apart. Never "log everything and grep".

**Perf branch.** For performance regressions, logs are usually wrong. Measure a baseline first (timing harness, `performance.now()`, profiler, query plan), then bisect. Measure first, fix second.
