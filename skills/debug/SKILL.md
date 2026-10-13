---
name: debug
description: "Disciplined diagnosis loop for bugs and performance regressions: build a tight red loop first, then hypothesise and fix. Use when something is broken, throwing, failing, flaky, or slow."
---

# Debug

Skip a phase only when explicitly justified.

**Redact every secret** you show (commands, outputs, artifacts) as `<REDACTED>`: build loops against env vars, quote only an artifact's signal lines, and if redacted output can't diagnose the bug, ask.

## Phase 1: Build a feedback loop

**This is the skill.** A **tight** pass/fail signal that goes red on _this_ bug finds the cause: spend disproportionate effort here and refuse to give up. Reach first for a failing test at a seam that reaches the bug. If that isn't tight at once, **read [LOOPS.md](LOOPS.md)**: nine more kinds of loop, tightening, flaky bugs, and what to do when none can be built.

Done when you have **already run** **one command** (show it and its output, redacted) that is:

- [ ] **Red-capable**: it drives the real bug path and asserts the **user's exact symptom**, not "no error".
- [ ] **Deterministic**: same verdict every run (flaky bugs: a pinned, high reproduction rate).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: unattended; a human only via `hitl-loop.template.sh`.

No red-capable command, no Phase 2: theorising from code first is the failure this skill prevents.

## Phase 2: Reproduce + minimise

Run the loop red. Confirm it shows the **user's** failure, not a nearby one, across runs, and capture the exact symptom. Then **minimise**: cut inputs, callers, config, data and steps one at a time, re-running after each, until every remaining element is load-bearing.

### Boundary decision

The fix answers to one rule, settled after the loop is red and before the fix.

**Read first**: the code around the input or state the bug touches, then every existing parser, validator, guard or invariant for the same thing, found by concept (its name, its spec, the type it produces), not by the bug's idiom: searching the failing expression finds more copies of the bug, not the rule that governs them. Read the input's own spec too (a standard, a schema, the docs). A wide search goes to a sub-agent.

**Then ask one question**, the boundary decision, in this shape, before any edit to source:

```
Boundary decision
Rule: <a rule or grammar, never examples: what input is valid, which object stays the same object, which path stays within which bound>
Accepts: <cases> / Rejects: <cases>, each one step from the repro; Rejects covers each part the Rule names, empty and with a wrong character
Adopts: <file:line of the existing rule, or what you searched>
A) <option>. Cost: <the cases it gets wrong, or what it adds>
B) <option>. Cost: <...>
Recommended: <letter>, because <what the code exists to guarantee>
```

Recommend the strictest option the repo's own rules or the input's spec support. Always print the block as plain text before any question or fix. Then ask through AskUserQuestion, recommended first; without one, the recommendation stands.

Its accepted and rejected cases are the **near-misses**, each a case in the Phase 5 test. A looser rule elsewhere is a follow-up, named in the commit message and listed for the retro. It never loosens the fix: the changed path follows the decision.

## Phase 3: Hypothesise

Rank **3–5 hypotheses** before testing any, each with its prediction: "If <X> is the cause, <changing Y> makes the bug disappear." No prediction, no hypothesis. **Show the ranked list to the user before testing**, without blocking: they may re-rank it or rule some out.

## Phase 4: Instrument

Each probe tests one prediction, **changing one variable at a time**. **Tag every debug log** with a unique prefix (`[DEBUG-a4f2]`). Before adding logs, or for a performance regression, read [LOOPS.md](LOOPS.md#instrumenting): tool preference and the perf branch.

## Phase 5: Fix + regression test

Call the Skill tool with "keel:tdd" and write the regression test **before the fix**, at a **correct seam**: where it exercises the **real bug pattern** as it occurs at the call site, not shallower (one caller when the bug needs several, a unit test that can't replay the chain). **If no correct seam exists, that is the finding**: flag it for the retro.

1. Turn the minimised repro and the near-misses into the failing regression test.
2. Watch it fail. Red forced by mutating code or a fixture: `diff` against a pristine copy to prove it landed.
3. Apply the fix, enforcing the boundary decision.
4. Watch it pass, then re-run the Phase 1 loop on the original, un-minimised scenario.

## Phase 6: Cleanup

- [ ] The original repro is gone, and the regression test passes (or the missing seam is documented)
- [ ] keel:tdd was loaded, and the regression test went red before the fix
- [ ] Every `[DEBUG-...]` log removed (`grep` the prefix); throwaway prototypes deleted or moved to a marked debug location
- [ ] The confirmed hypothesis is in the commit or PR message

## Phase 7: Commit, review, retro, finish

1. Run the repo's lint, typecheck and full suite (found as keel:build does): all green.
2. From the current branch (the **starting branch**), run `sh <this skill's directory>/../review/new-branch.sh fix/<slug>`, which also writes its ledger; commit the fix and regression test there.
3. Show the Phase 1 loop red before, green after.
4. Call the Skill tool with "keel:review", fixed point the starting branch's `HEAD`, spec the boundary decision, the bug report and the confirmed hypothesis.
5. Write each finding's disposition by [LEDGER.md](../review/LEDGER.md) (escalated ones await the user), fix what you reproduced, re-run step 1, and commit any change as `fix(<slug>): review findings`.
6. Call the Skill tool with "keel:retro", asking first "what would have prevented this?". A missing correct seam is a candidate.
7. Ask through `AskUserQuestion` (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*.
