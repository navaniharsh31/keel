---
name: build
description: "Build approved tickets or a small agreed change: test-first, reviewed, committed. Use after tickets are approved (G4), to resume an in-flight spec, or for a single-slice change after G1."
---

# Build

Autonomous from here: between the start and the finish question, stop only for flow.md's stops.

**Check commands** (install, typecheck, lint, single test file, full suite) are discovered from the repo every time: `package.json` scripts, a Makefile, the CI workflow. Hold them in this session and pass them on.

Pick the mode: **spec mode** when called with a spec (`docs/specs/<slug>/spec.md`, approved or building), **inline mode** when called from G1 with no spec.

## Inline mode

1. **Preflight.** The working tree may hold only the glossary and ADR changes from grilling (`GLOSSARY.md`, `docs/adr/`); anything else, stop and ask. Discover the check commands and run the full suite once for the "before" test count (red here is pre-existing: stop and ask). Note the current branch as the **starting branch** and its `HEAD` as the fixed point, create `feat/<slug>` from it, and commit any glossary/ADR changes as `docs(<slug>): glossary and ADRs`. Done when you are on `feat/<slug>` with a clean tree.
2. **Build.** Call the Skill tool with "keel:tdd" and build at the seams agreed during grilling. Typecheck and run single test files often; run lint and the full suite once at the end, then commit as `feat(<slug>): <summary>`. Done when that commit exists and the suite is green.
3. **Review.** Call the Skill tool with "keel:review" with the noted fixed point; the Spec axis gets the G1 summary as its spec. Done when its summary line gives a count and a worst issue per axis.
4. **Fix**, in this session, to the fixer brief in spec-mode step 5. Done when the suite is green and every finding is fixed, refuted with a reason, or listed as skipped with a reason.
5. Run **Finish**.

## Spec mode

### 1. Preflight (first entry, spec `Status: approved`)

- The working tree may hold only keel's own uncommitted artifacts (`docs/specs/<slug>/`, `GLOSSARY.md`, `docs/adr/`). Anything else: stop and ask.
- Discover the check commands. Run the full suite once and note its test count (the "before" number). A red suite here is pre-existing: stop and ask.
- Create the **integration branch** `feat/<slug>` from `HEAD` (or follow the repo's existing branch naming if it has one). The branch you started on is the **starting branch**.
- In spec.md set `Status: building`, `Branch: <integration branch>`, and `Base: <short SHA of the starting HEAD> (<starting branch>)`.
- Commit the spec, tickets, and glossary/ADR changes as `docs(<slug>): spec and tickets`, with `Tests before: <N>` in the commit body.

Done when the integration branch exists and that commit is its tip.

### 2. Resume (re-entry, spec `Status: building`)

The branches are the truth. Check out `Branch:`, and read the "before" count from the body of the `docs(<slug>): spec and tickets` commit. For each ticket marked `in-progress`, find its `feat(<slug>): <NN> ` commit:

- on the integration branch: the ticket is done;
- only on its ticket branch: it finished but never merged, so dispatch its merger (step 3);
- nowhere: set it back to `ready`. Its leftover worktree (`git worktree list`), or uncommitted changes on the integration branch if it ran there, is the state its next implementer continues from.

Tickets marked `blocked` carry their question in Notes and rejoin the blocked protocol below.

Done when the integration branch is checked out and no ticket is `in-progress` without a merger dispatched.

### 3. Frontier loop

The **frontier** is every `ready` ticket whose blockers are all `done`. Repeat until every ticket is `done`:

- **Bookkeeping commit.** Before each dispatch wave, write every header change since the last one (`in-progress` for the tickets about to go, `blocked` or `ready` transitions with their Notes, `Commit: <SHA>` on tickets that finished) and commit as `chore(<slug>): dispatch <NN, NN>`. This keeps the tree clean for merges and worktrees.
- **One ticket, nothing else in flight:** dispatch one implementer subagent on the integration branch itself.
- **Otherwise:** for each frontier ticket, up to 3 in flight at once, create a worktree from the integration tip, `git worktree add ../<repo>-keel-<slug>-<NN> -b <integration branch>-<NN> <integration branch>`, and dispatch an implementer subagent into it. Dispatch them in parallel, in the background where the harness allows.
- Build each implementer prompt from [IMPLEMENTER.md](IMPLEMENTER.md): context pointers, never copies, except the hard constraints, which you quote word for word from the spec.
- **When an implementer reports done** from a worktree, dispatch a merger subagent from [MERGER.md](MERGER.md), one merger at a time. After a green merge, remove that worktree and delete its merged branch (`git branch -d`). Then recompute the frontier and dispatch newly unblocked tickets right away.
- **Blocked protocol.** An implementer that reports `BLOCKED: <question>` has guessed nothing. Set its ticket to `blocked` with the question in its Notes, and keep working the rest of the frontier. When nothing else can move, put every open question to the user at once (an unplanned stop), set each ticket back to `ready` with the answer in its Notes, and re-dispatch it into its existing worktree with the answer in `Continue from:`.
- An implementer or merger that reports `RED:` after a real attempt is an unplanned stop: show the failing tests and ask. A merger's `RED:` means it undid the merge, so the integration branch is still green; keep the ticket branch and its worktree for the retry.

Done when every ticket is `done` on the integration branch and the full suite is green there.

### 4. Review

Call the Skill tool with "keel:review" with the fixed point = the `Base:` SHA and the spec path. Done when its summary line gives a count and a worst issue per axis.

### 5. Fix

Dispatch one fixer subagent with the review report, the spec path, and the check commands. **Fixer brief:** before changing code, reproduce or refute each finding, and record a refuted finding with its reason, never as "fixed"; fix every hard Standards violation and every Spec finding you reproduced; fix the judgement-call smells you agree with and list each one you skipped with a reason; never edit, skip, loosen or delete existing tests or test config to get green; if a test looks wrong, report `BLOCKED:`; run the full suite; commit as `fix(<slug>): review findings`; if the suite stays red after a real attempt, report `RED:` with the failing tests; report in 150 words or fewer.

A fixer that reports `BLOCKED:` or `RED:` is an unplanned stop: show it and ask.

Done when the fixer reports green and every finding is fixed, refuted with a reason, or listed as skipped with a reason.

## Finish

1. In spec mode, set the spec's `Status: done` with the header line `This spec is a historical record. Code, GLOSSARY.md and ADRs win on conflict.` below `Base:`, add the last `Commit:` notes, and commit as `docs(<slug>): done`.
2. Give the summary, with evidence: tickets done, test count before → after, the full-suite output line, review findings per axis (fixed / refuted / skipped), and every refuted or skipped item with its reason.
3. Call the Skill tool with "keel:retro". Its commits land on the feature branch, so they ride along with whatever the user picks next.
4. Ask through `AskUserQuestion` on its own (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*. Merge means `git checkout <starting branch> && git merge --no-ff <feature branch>`. A PR means call the Skill tool with "keel:pr" for the body, then `gh pr create`.
5. Remove any keel worktrees still listed by `git worktree list`.

Done when the user's pick is carried out and `git worktree list` shows only the main worktree.

## Done

- [ ] Every ticket is `done` (spec mode) and the full suite is green on the feature branch.
- [ ] Every review finding is fixed, refuted with a reason, or listed as skipped with a reason.
- [ ] The spec says `Status: done` (spec mode), retro has run, and the user's finish pick is carried out.
