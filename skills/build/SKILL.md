---
name: build
description: Build approved tickets or a small agreed change: test-first, reviewed, committed. Use after tickets are approved (G4), to resume an in-flight spec, or for a single-slice change after G1.
---

# Build

Autonomous from here: between the start and the finish question, stop only for the unplanned stops in flow.md (a decision the spec doesn't settle, a one-way door, a suite you can't turn green, a dirty working tree at the start).

**Check commands** (install, typecheck, lint, single test file, full suite) are discovered from the repo every time: `package.json` scripts, a Makefile, the CI workflow. Hold them in this session and pass them on; write them nowhere.

Pick the mode: **spec mode** when called with a spec (`docs/specs/<slug>/spec.md`, approved or building), **inline mode** when called from G1 with no spec.

## Inline mode

1. Require a clean working tree (`git status --porcelain` empty), else stop and ask. Discover the check commands. If the current branch is the default branch, create `feat/<slug>`. Note `HEAD` as the fixed point.
2. Call the Skill tool with "keel:tdd" and build at the seams agreed during grilling. Typecheck and run single test files often; run the full suite once at the end.
3. Call the Skill tool with "keel:review" with the noted fixed point; the Spec axis gets the G1 summary as its spec.
4. Fix every hard Standards violation and every Spec finding, and the judgement-call smells you agree with. Run the full suite until green, then commit as `feat(<slug>): <summary>`.
5. Run the **Finish** step below (skipping its spec edit), then call the Skill tool with "keel:retro".

## Spec mode

### 1. Preflight (first entry, spec `Status: approved`)

- The working tree may hold only keel's own uncommitted artifacts (`docs/specs/<slug>/`, `GLOSSARY.md`, `docs/adr/`). Anything else: stop and ask.
- Discover the check commands. Run the full suite once and note its test count (the "before" number). A red suite here is pre-existing: stop and ask.
- Create the **integration branch** `feat/<slug>` from `HEAD` (or follow the repo's existing branch naming if it has one).
- In spec.md set `Status: building`, `Branch: feat/<slug>`, and `Base: <short SHA of the starting HEAD> (<starting branch>)`.
- Commit the spec, tickets, and glossary/ADR changes as `docs(<slug>): spec and tickets`.

Done when the integration branch exists and that commit is its tip.

### 2. Resume (re-entry, spec `Status: building`)

The branch tip is the truth. Check out `Branch:`. For each ticket marked `in-progress`, look for its commit (`git log <Base SHA>..HEAD --grep "<slug>): <NN> "`): if present, the ticket is done; otherwise set it back to `ready`. A leftover worktree from the last run (`git worktree list`) is reused for its ticket, and uncommitted changes on the integration branch belong to the ticket that ran there: either way, the next implementer continues from that state. Note the "before" test count by running the full suite at `Base`, or skip it and say so in the summary.

### 3. Frontier loop

The **frontier** is every `ready` ticket whose blockers are all `done`. Repeat until every ticket is `done`:

- **Bookkeeping commit.** Before dispatching, set each ticket you are about to dispatch to `Status: in-progress`, append `Commit: <SHA>` to the Notes of tickets that finished since the last commit, and commit as `chore(<slug>): dispatch <NN, NN>`. This keeps the tree clean for merges and worktrees.
- **One ticket, nothing else in flight:** dispatch one implementer subagent on the integration branch itself.
- **Otherwise:** for each frontier ticket, up to 3 in flight at once, create a worktree from the integration tip, `git worktree add ../<repo>-keel-<NN> -b feat/<slug>-<NN>`, and dispatch an implementer subagent into it. Dispatch them in parallel, in the background where the harness allows.
- Build each implementer prompt from [IMPLEMENTER.md](IMPLEMENTER.md): context pointers, never copies.
- **When an implementer reports done** from a worktree, dispatch a merger subagent from [MERGER.md](MERGER.md), one merger at a time. After a green merge, remove that worktree and delete its merged branch (`git branch -d`). Then recompute the frontier and dispatch newly unblocked tickets right away.
- **Blocked protocol.** An implementer that reports `BLOCKED: <question>` has guessed nothing. Set its ticket to `blocked` and keep working the rest of the frontier. When nothing else can move, put every open question to the user at once (an unplanned stop), record each answer in its ticket's Notes, set the ticket to `ready`, and re-dispatch it into its existing worktree.
- A merger that reports red after a real attempt to fix merge breakage is an unplanned stop: show the failure and ask.

Done when every ticket is `done` on the integration branch and the full suite is green there.

### 4. Review

Call the Skill tool with "keel:review" with the fixed point = the `Base:` SHA and the spec path.

### 5. Fix

Dispatch one fixer subagent with the review report, the spec path, and the check commands. Its brief: fix every hard Standards violation and every Spec finding; fix the judgement-call smells it agrees with and list each one it skipped with a reason; run the full suite until green; commit as `fix(<slug>): review findings`; report in 150 words or fewer.

Done when the fixer reports green and every finding is either fixed or listed as skipped with a reason.

## Finish

1. In spec mode, set the spec's `Status: done`, append the last `Commit:` notes, and commit as `docs(<slug>): done`.
2. Give the summary, with evidence: tickets done, test count before → after, the full-suite output line, review findings per axis (fixed / skipped), and every skipped item with its reason.
3. Ask through `AskUserQuestion` (a one-way door): *Merge into <starting branch> locally* / *Open a PR (uses keel:pr)* / *Leave the branch*. Merge means `git checkout <starting branch> && git merge --no-ff feat/<slug>`. A PR means call the Skill tool with "keel:pr" for the body, then `gh pr create`.
4. Remove any keel worktrees still listed by `git worktree list`.
5. In spec mode, call the Skill tool with "keel:retro".

## Done

- [ ] Every ticket is `done` (spec mode) and the full suite is green on the integration branch.
- [ ] Every review finding is fixed or listed as skipped with a reason.
- [ ] The spec says `Status: done` (spec mode), and the user has picked a finish option.
