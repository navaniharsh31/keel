---
name: debug
description: "Disciplined diagnosis loop for bugs and performance regressions: build a tight red loop first, then hypothesise and fix. Use when something is broken, throwing, failing, flaky, or slow."
---

# Debug

A discipline for hard bugs. Skip phases only when explicitly justified.

## Redact

This skill has you show commands, outputs and captured artifacts. **Redact every secret first**: write `<REDACTED>` in its place. Build loops against env vars, so the credential stays in the environment rather than in what you show. Captured artifacts carry auth headers: quote only the lines that carry the signal.

If the redacted output is not enough to diagnose the bug, say so and ask the user.

## Phase 1: Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a **tight** pass/fail signal for the bug (one that goes red on _this_ bug), you will find the cause; bisection, hypothesis-testing, and instrumentation all just consume it. If you don't have one, no amount of staring at code will save you.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

**Read [LOOPS.md](LOOPS.md) before building the loop**: the ten ways to construct one, in order of preference, how to tighten it, and what to do for non-deterministic bugs or when no loop can be built.

### Completion criterion: a tight loop that goes red

Phase 1 is done when the loop is **tight** and **red-capable**: you can name **one command** (a script path, a test invocation, a curl) that you have **already run at least once** (show the invocation and its output, redacted), and that is:

- [ ] **Red-capable**: it drives the actual bug code path and asserts the **user's exact symptom**, so it can go red on this bug and green once fixed. Not "runs without erroring"; it must be able to _catch this specific bug_.
- [ ] **Deterministic**: same verdict every run (flaky bugs: a pinned, high reproduction rate, per LOOPS.md).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: you can run it unattended; a human in the loop only via `hitl-loop.template.sh`.

If you catch yourself reading code to build a theory before this command exists, **stop: jumping straight to a hypothesis is the exact failure this skill prevents.** No red-capable command, no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop. Watch it go red as the bug appears.

Confirm:

- [ ] The loop produces the failure mode the **user** described, not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing) so later phases can verify the fix actually addresses it.

### Minimise

Once it's red, shrink the repro to the **smallest scenario that still goes red**. Cut inputs, callers, config, data, and steps **one at a time**, re-running the loop after each cut, and keep only what's load-bearing for the failure.

Why bother: a minimal repro shrinks the hypothesis space in Phase 3 (fewer moving parts left to suspect) and becomes the clean regression test in Phase 5.

Done when **every remaining element is load-bearing**: removing any one of them makes the loop go green.

Do not proceed until you have reproduced **and** minimised.

### Near-misses

For every bug, list the **near-misses** next to the minimised repro: cases one step from it that must keep their current behaviour after the fix. For input handling, the malformed variants that must still be rejected (trailing junk, a missing or doubled delimiter, a wrong separator, a non-numeric field, an empty value). For state identity, the object that must stay the same object, the second caller that must see the same result. For performance, the neighbouring path that must stay fast. Each one becomes a case in the Phase 5 test; some already pass, which is the point.

Then search the repo for code that already parses, validates or maintains the same thing (grep its name; dispatch a sub-agent if the search is wide). An existing rule **stricter** than the fix you'd write: adopt it. A **looser** one: a second bug site; name it in the commit message and the retro, don't fix it here.

## Phase 3: Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe: discard or sharpen it.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just deployed a change to #3"), or know hypotheses they've already ruled out. Cheap checkpoint, big time saver. Don't block on it; proceed with your ranking if the user is AFK.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

**Read [LOOPS.md](LOOPS.md#instrumenting) before probing**: which tools to prefer, and the perf branch for performance regressions.

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep. Untagged logs survive; tagged logs die.

## Phase 5: Fix + regression test

Write the regression test **before the fix**, but only if there is a **correct seam** for it. Write it by the keel:tdd rules: call the Skill tool with "keel:tdd".

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (single-caller test when the bug needs multiple callers, unit test that can't replicate the chain that triggered the bug), a regression test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it. The codebase architecture is preventing the bug from being locked down. Flag it for the retro as a candidate.

If a correct seam exists:

1. Turn the minimised repro and its near-misses into a failing test at that seam.
2. Watch it fail. If you forced the red by mutating code or a fixture, `diff` against a pristine copy to prove the mutation landed before you trust it.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

## Phase 6: Cleanup

Required before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or absence of seam is documented)
- [ ] keel:tdd was loaded, and the regression test went red before the fix
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix)
- [ ] Throwaway prototypes deleted (or moved to a clearly-marked debug location)
- [ ] The hypothesis that turned out correct is stated in the commit / PR message, so the next debugger learns

## Phase 7: Commit, review, retro, finish

1. Run the repo's lint, typecheck and full suite (discover them as keel:build does); all green.
2. Create `fix/<slug>` from the current branch (the **starting branch**) and its ledger ([LEDGER.md](../review/LEDGER.md)). Commit the fix and its regression test there.
3. Show the evidence: the Phase 1 loop red before, green after.
4. Call the Skill tool with "keel:review", fixed point the starting branch's `HEAD` (where `fix/<slug>` began). Its spec is the bug report, the near-misses and the confirmed hypothesis.
5. Write every finding's disposition to the ledger by LEDGER.md's rules (an escalated finding waits for the user's answer), fix what you reproduced, re-run step 1, and commit as `fix(<slug>): review findings` if anything changed.
6. Call the Skill tool with "keel:retro", asking first "what would have prevented this?". A missing correct seam is one of its candidates.
7. Ask through `AskUserQuestion` (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*.
