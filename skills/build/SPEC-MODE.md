# Build: spec mode

Read by keel:build when it is called with a spec. Steps 1 and 2 pick the entry; then run steps 3 to 6, and end with the Finish steps in [SKILL.md](SKILL.md).

## 1. Preflight (first entry, spec `Status: approved`)

- The working tree may hold only keel's own uncommitted artifacts (`docs/specs/<slug>/`, `GLOSSARY.md`, `docs/adr/`). Anything else: stop and ask.
- Discover the check commands. Run the full suite once and note its test count (the "before" number). A red suite here is pre-existing: stop and ask.
- Note the branch you started on as the **starting branch**. Create the **integration branch** `feat/<slug>` (or follow the repo's existing branch naming if it has one) from `HEAD` together with its ledger: `sh <this skill's directory>/../review/new-branch.sh <integration branch>` ([LEDGER.md](../review/LEDGER.md)). Ticket branches get no ledger: step 3 creates them with `git worktree add`.
- In spec.md set `Status: building`, `Branch: <integration branch>`, and `Base: <short SHA of the starting HEAD> (<starting branch>)`.
- Commit the spec, tickets, and glossary/ADR changes as `docs(<slug>): spec and tickets`, with `Tests before: <N>` in the commit body.

Done when the integration branch exists and that commit is its tip.

## 2. Resume (re-entry, spec `Status: building`)

The branches are the truth. Check out `Branch:`, and read the "before" count from the body of the `docs(<slug>): spec and tickets` commit. For each ticket marked `in-progress`, find its `feat(<slug>): <NN> ` commit:

- on the integration branch: the ticket is done;
- only on its ticket branch: it finished but never merged, so dispatch its merger (step 3);
- nowhere: set it back to `ready`. Its leftover worktree (`git worktree list`), or uncommitted changes on the integration branch if it ran there, is the state its next implementer continues from.

Tickets marked `blocked` carry their question in Notes and rejoin the blocked protocol below.

Done when the integration branch is checked out and no ticket is `in-progress` without a merger dispatched.

## 3. Frontier loop

The **frontier** is every `ready` ticket whose blockers are all `done`. Repeat until every ticket is `done`:

- **Bookkeeping commit.** Before each dispatch wave, write every header change since the last one (`in-progress` for the tickets about to go, `blocked` or `ready` transitions with their Notes, `Commit: <SHA>` on tickets that finished) and commit as `chore(<slug>): dispatch <NN, NN>`. This keeps the tree clean for merges and worktrees.
- **One ticket, nothing else in flight:** dispatch one implementer subagent on the integration branch itself.
- **Otherwise:** for each frontier ticket, up to 3 in flight at once, create a worktree from the integration tip, `git worktree add ../<repo>-keel-<slug>-<NN> -b <integration branch>-<NN> <integration branch>`, and dispatch an implementer subagent into it. Dispatch them in parallel, in the background where the harness allows.
- Build each implementer prompt from [IMPLEMENTER.md](IMPLEMENTER.md): context pointers, never copies, except the hard constraints, which you quote word for word from the spec.
- **When an implementer reports done** from a worktree, dispatch a merger subagent from [MERGER.md](MERGER.md), one merger at a time. After a green merge, remove that worktree and delete its merged branch (`git branch -d`). Then recompute the frontier and dispatch newly unblocked tickets right away.
- **Blocked protocol.** An implementer that reports `BLOCKED: <question>` has guessed nothing. Set its ticket to `blocked` with the question in its Notes, and keep working the rest of the frontier. When nothing else can move, put every open question to the user at once (an unplanned stop), set each ticket back to `ready` with the answer in its Notes, and re-dispatch it into its existing worktree with the answer in `Continue from:`.
- An implementer or merger that reports `RED:` after a real attempt is an unplanned stop: show the failing tests and ask. A merger's `RED:` means it undid the merge, so the integration branch is still green; keep the ticket branch and its worktree for the retry.

Done when every ticket is `done` on the integration branch and the full suite is green there.

## 4. Review

Call the Skill tool with "keel:review" with the fixed point = the `Base:` SHA and the spec path. Done when its summary line gives a count and a worst issue per axis. Reviewing the diff yourself is not this step.

## 5. Fix

Dispatch one fixer subagent with the review report, the spec path, the ledger path, and the check commands. **Fixer brief:**

1. Before changing code, reproduce or refute every finding in the ledger, including `C` findings.
2. Fix what you reproduced.
3. Write one disposition line per finding in [LEDGER.md](../review/LEDGER.md)'s forms, by its rules for fixed, refuted, style and escalated.
4. Keep existing tests and test config as they are, except where a test's expectation is what the work changes (keel:tdd's probes rule, with a reason in your report). Getting green is never that reason; if a test looks wrong, report `BLOCKED:`.
5. Run the full suite and commit as `fix(<slug>): review findings`. If the suite stays red after a real attempt, report `RED:` with the failing tests.
6. Report in 150 words or fewer, with every escalated question.

A fixer that reports `BLOCKED:`, `RED:` or an escalated finding is an unplanned stop: show it and ask, then write each answer to the ledger as LEDGER.md says.

Done when the fixer reports green and every finding id is fixed or refuted in the ledger.

## 6. Close the spec

Set the spec's `Status: done` with the header line `This spec is a historical record. Code, GLOSSARY.md and ADRs win on conflict.` below `Base:`, add the last `Commit:` notes, and commit as `docs(<slug>): done`. Then run Finish in SKILL.md.
