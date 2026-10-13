---
name: debug
description: "Disciplined diagnosis loop for bugs and performance regressions: build a tight red loop first, then hypothesise and fix. Use when something is broken, throwing, failing, flaky, or slow."
---

# Debug

A discipline for hard bugs. Skip phases only when explicitly justified.

## Redact

**Redact every secret** in the commands, outputs and artifacts you show: write `<REDACTED>` in its place. Build loops against env vars, and quote only the lines of a captured artifact that carry the signal. If the redacted output can't diagnose the bug, say so and ask the user.

## Phase 1: Build a feedback loop

**This is the skill.** With a **tight** pass/fail signal that goes red on _this_ bug, you will find the cause; everything after only consumes it. Without one, no amount of staring at code will save you. Spend disproportionate effort here, and refuse to give up.

Reach first for a failing test at a seam that reaches the bug. If that isn't tight at once, **read [LOOPS.md](LOOPS.md)**: nine more ways to build a loop, how to tighten it, flaky bugs, and what to do when no loop can be built.

Phase 1 is done when you can name **one command** you have **already run** (show it and its output, redacted) that is:

- [ ] **Red-capable**: it drives the real bug path and asserts the **user's exact symptom**, not "runs without erroring".
- [ ] **Deterministic**: same verdict every run (flaky bugs: a pinned, high reproduction rate).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: unattended; a human in the loop only via `hitl-loop.template.sh`.

Reading code to build a theory before this command exists is the exact failure this skill prevents. No red-capable command, no Phase 2.

## Phase 2: Reproduce + minimise

Run the loop and watch it go red. Confirm it shows the failure the **user** described, not a nearby one (wrong bug = wrong fix), that it reproduces across runs (flaky bugs: at a rate you can debug against), and capture the exact symptom to check the fix against.

Then **minimise**: cut inputs, callers, config, data and steps one at a time, re-running the loop after each cut, until every remaining element is load-bearing (removing any one turns the loop green). The minimal repro shrinks the hypothesis space and becomes the regression test.

### Boundary decision

The fix answers to one stated rule, settled after the loop is red and before the fix.

**Read first.** Read the code around the input or state the bug touches. Then find every existing parser, validator, guard or invariant for the same thing by concept (its name, its spec, the type it produces), not by the bug's idiom: a search for the failing expression finds more copies of the bug, not the rule that should govern them. Read the input's own spec too (a standard, a schema, the docs). Dispatch a sub-agent if the search is wide.

**Then ask one question**, the boundary decision. It states:

- the rule the fix enforces, as a rule or grammar, never as examples: what input is valid, which object stays the same object, which path stays within which bound;
- the cases it accepts and the cases it rejects, each one step from the repro;
- the existing rule it adopts, by `file:line` (or what you searched, if none exists).

Letter the options, each with its cost: the cases it gets wrong, or what it adds. Recommend the strictest option that the repo's own rules or the input's spec support, and give as the reason what the code exists to guarantee. Ask it through AskUserQuestion, recommended first. Without it, print the question and go on: the recommendation stands.

Its accepted and rejected cases are the bug's **near-misses**; each becomes a case in the Phase 5 test. A looser rule elsewhere is a follow-up: name it in the commit message and list it for the retro. It never loosens the fix: the changed path follows the decision.

## Phase 3: Hypothesise

Generate **3–5 ranked hypotheses** before testing any; a single one anchors on the first plausible idea. Each states its prediction: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse." One with no prediction is a vibe: sharpen or discard it.

**Show the ranked list to the user before testing**: they may re-rank it at once or know what is ruled out. Don't block on it; if the user is AFK, proceed with your ranking.

## Phase 4: Instrument

Each probe tests one prediction from Phase 3. **Change one variable at a time.** **Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`, so cleanup is one grep. Before adding logs, or for a performance regression, read [LOOPS.md](LOOPS.md#instrumenting): tool preference and the perf branch.

## Phase 5: Fix + regression test

Write the regression test **before the fix**, by the keel:tdd rules (call the Skill tool with "keel:tdd"), at a **correct seam**: one where the test exercises the real bug pattern as it occurs at the call site. A seam too shallow (one caller when the bug needs several, a unit test that can't replay the chain behind the bug) gives false confidence. **If no correct seam exists, that is the finding**: note it and flag it for the retro as a candidate.

At a correct seam:

1. Turn the minimised repro and the near-misses into a failing test.
2. Watch it fail. If you forced the red by mutating code or a fixture, `diff` against a pristine copy to prove the mutation landed.
3. Apply the fix, enforcing the boundary decision.
4. Watch it pass.
5. Re-run the Phase 1 loop against the original, un-minimised scenario.

## Phase 6: Cleanup

Required before declaring done:

- [ ] The original repro no longer reproduces, and the regression test passes (or the missing seam is documented)
- [ ] keel:tdd was loaded, and the regression test went red before the fix
- [ ] All `[DEBUG-...]` instrumentation removed (`grep` the prefix); throwaway prototypes deleted or moved to a clearly marked debug location
- [ ] The hypothesis that turned out correct is stated in the commit or PR message, so the next debugger learns

## Phase 7: Commit, review, retro, finish

1. Run the repo's lint, typecheck and full suite (discover them as keel:build does); all green.
2. Create `fix/<slug>` from the current branch (the **starting branch**) and its ledger ([LEDGER.md](../review/LEDGER.md)). Commit the fix and its regression test there.
3. Show the evidence: the Phase 1 loop red before, green after.
4. Call the Skill tool with "keel:review", fixed point the starting branch's `HEAD` (where `fix/<slug>` began). Its spec is the boundary decision, the bug report and the confirmed hypothesis.
5. Write every finding's disposition to the ledger by LEDGER.md's rules (an escalated finding waits for the user's answer), fix what you reproduced, re-run step 1, and commit as `fix(<slug>): review findings` if anything changed.
6. Call the Skill tool with "keel:retro", asking first "what would have prevented this?". A missing correct seam is one of its candidates; each looser-rule follow-up goes on its follow-up list.
7. Ask through `AskUserQuestion` (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*.
