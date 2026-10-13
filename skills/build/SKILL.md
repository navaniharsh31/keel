---
name: build
description: "Build approved tickets or a small agreed change: test-first, reviewed, committed. Use after tickets are approved (G4), to resume an in-flight spec, or for a single-slice change after G1."
---

# Build

Autonomous from here: between the start and the finish question, stop only for flow.md's stops.

**Check commands** (install, typecheck, lint, single test file, full suite): discover them from the repo every time (`package.json` scripts, a Makefile, the CI workflow), hold them and pass them on.

**Spec mode**, when called with a spec (`docs/specs/<slug>/spec.md`, approved or building): read [SPEC-MODE.md](SPEC-MODE.md) now and follow it (preflight or resume, the frontier loop, review, the fixer), then run Finish. **Inline mode**, called from G1 with no spec, is below.

## Inline mode

1. **Preflight.** The tree may hold only grilling's `GLOSSARY.md` and `docs/adr/` changes; anything else, stop and ask. Run the full suite once for the "before" test count (red here is pre-existing: stop and ask). Note the current branch as the **starting branch** and its `HEAD` as the fixed point, create `feat/<slug>` from it and its ledger with its `created` line ([LEDGER.md](../review/LEDGER.md)), and commit any glossary/ADR changes as `docs(<slug>): glossary and ADRs`. Done when you are on `feat/<slug>` with a clean tree.
2. **Build.** Call the Skill tool with "keel:tdd" and build at the seams agreed during grilling. Typecheck and run single test files often; run lint and the full suite once at the end, then commit as `feat(<slug>): <summary>`. Done when that commit exists and the suite is green.
3. **Review.** Call the Skill tool with "keel:review" with the noted fixed point; the Spec axis gets the G1 summary as its spec. Done when its summary line gives a count and a worst issue per axis. Reviewing the diff yourself is not this step.
4. **Fix**, in this session with no fixer subagent. Before changing code, reproduce or refute every finding (`C` included); fix what you reproduced; write one disposition per finding by LEDGER.md, putting each escalated one to the user. Keep existing tests and test config except as keel:tdd's probes rule allows, with a reason in your summary; getting green is never that reason, and a test that looks wrong is a question for the user. Run the full suite and commit as `fix(<slug>): review findings`. Done when the suite is green and every finding id is fixed or refuted in the ledger.
5. Run **Finish**.

## Finish

1. Give the summary, with evidence: tickets done (spec mode), test count before → after, the full-suite output line, review findings per axis from the ledger (fixed / refuted / escalated), and each refuted or escalated item's evidence or outcome.
2. Call the Skill tool with "keel:retro". Its commits land on the feature branch and ride along with the user's pick.
3. Ask through `AskUserQuestion` on its own (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*. Merge means `git checkout <starting branch> && git merge --no-ff <feature branch>`. A PR means call the Skill tool with "keel:pr" for the body, then `gh pr create`.
4. Remove any keel worktrees still listed by `git worktree list`.

Done when the user's pick is carried out and `git worktree list` shows only the main worktree.

## Done

- [ ] Every ticket is `done` (spec mode) and the full suite is green on the feature branch.
- [ ] keel:tdd was loaded, and every new test went red first.
- [ ] The ledger has the review line, and every finding is fixed or refuted.
- [ ] The spec says `Status: done` (spec mode), retro has run, and the user's finish pick is carried out.
