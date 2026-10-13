---
name: review
description: Two-axis review (Standards and Spec) of a diff against a fixed point, run as parallel sub-agents. Use after building, or when the user asks to review a branch, PR, or changes since X.
---

Review the diff between `HEAD` and a fixed point on two axes:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the originating spec?

A change can pass one axis and fail the other, so each runs as one of two **parallel sub-agents** and reports separately. Only proven defects are findings; unproven concerns are residual risks.

### 1. Pin the fixed point

Use the fixed point the caller or user gave (a SHA, branch, tag, `HEAD~5`), else the `Base:` SHA of the spec under `docs/specs/` whose `Branch:` matches the current branch, else ask. Confirm `git rev-parse <fixed-point>` resolves and `git diff <fixed-point>...HEAD` (three-dot) is non-empty, so a bad ref fails here, not in the sub-agents. Note the diff command and `git log <fixed-point>..HEAD --oneline`.

### 2. Identify the spec source

What the caller passed (a spec path, the G1 summary in inline mode, or a bug's boundary decision with its report and confirmed hypothesis), else the `docs/specs/<slug>/` whose `Branch:` or slug matches the current branch (its `spec.md` and every file under `tickets/`), else ask. With no spec at all, skip the Spec sub-agent and report "no spec available".

### 3. Identify the standards sources

Every file that documents how code should be written here, always including `CODING_STANDARDS.md` and `CONTRIBUTING.md` when they exist.

### 4. Spawn both sub-agents in parallel

Issue both calls together, in the foreground. Each prompt names its brief by absolute path and adds only the inputs below; never restate, summarise or trim a brief.

- **Standards**: "Read `<this skill's dir>/STANDARDS.md` and follow it." Then the diff command, the commit list and the standards files.
- **Spec**: "Read `<this skill's dir>/SPEC.md` and follow it." Then the diff command, the commit list, and the spec: its paths, or the G1 summary or boundary decision text.

**Claude Code's bundled `/code-review` runs only on the user's ask**; then read [CODE-REVIEW.md](CODE-REVIEW.md) and follow it.

### 5. Aggregate

Present the reports under `## Standards` and `## Spec`, verbatim or lightly cleaned, then `## Code review` if it ran. Gather both axes' residual risks under one `## Residual risks` heading, each tagged with its axis. Move any finding without its probe or quoted line there.

End with a one-line summary: findings per axis and the worst issue _within each axis_ (if any), the residual risk count, then the code review's count if it ran. Never pick one winner across axes or rank the code review against them: the separation exists to prevent that reranking.

**Write the ledger.** Number every finding: `S<n>` Standards, `P<n>` Spec, `C<n>` code review. Residual risks get no id. When the current branch has a ledger ([LEDGER.md](LEDGER.md)), read it, then append the `review` line (with the summary line) and one `finding` line per id. A branch with no ledger is not keel's: create none.

Done when both axes have reported (or the Spec axis is skipped), the summary line names a count and a worst issue per axis, and a branch with a ledger holds the `review` line and every `finding` line.
