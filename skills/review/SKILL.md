---
name: review
description: Two-axis review (Standards and Spec) of a diff against a fixed point, run as parallel sub-agents. Use after building, or when the user asks to review a branch, PR, or changes since X.
---

Two-axis review of the diff between `HEAD` and a fixed point:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the originating spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings. It reports only proven defects; unproven concerns are residual risks. Claude Code's bundled `/code-review` runs only when the user asks for it.

## Process

### 1. Pin the fixed point

Use the fixed point the caller or user gave (a commit SHA, branch name, tag, `main`, `HEAD~5`, etc.). If none was given, use the `Base:` SHA of the spec under `docs/specs/` whose `Branch:` matches the current branch. If there is no such spec, ask for it.

Confirm it resolves (`git rev-parse <fixed-point>`) and that `git diff <fixed-point>...HEAD` (three-dot, against the merge-base) is non-empty, so a bad ref fails here, not inside two sub-agents. Note the diff command and `git log <fixed-point>..HEAD --oneline`.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. What the caller passed: a spec path, the G1 summary (inline mode), or a bug's boundary decision with its report and confirmed hypothesis.
2. The `docs/specs/<slug>/` whose `Branch:` matches the current branch, or whose slug matches the branch name: its `spec.md` plus every ticket file under `tickets/`.
3. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Search the repo for every file that documents how code should be written. When `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists, it must be on the list.

### 4. Spawn both sub-agents in parallel

Issue both sub-agent calls together, in the foreground. Each prompt names its brief by absolute path, in this skill's directory, and adds only the inputs below. Never restate, summarise or trim a brief: the reviewer reads it itself.

- **Standards**: "Read `<this skill's dir>/STANDARDS.md` and follow it." Then the diff command, the commit list and the standards files from step 3.
- **Spec**: "Read `<this skill's dir>/SPEC.md` and follow it." Then the diff command, the commit list, and the spec: its paths, or the G1 summary or boundary decision text.

If the spec is missing, skip the Spec sub-agent and note this in the final report.

**Bundled code review, only on the user's ask.** When the user asked for `/code-review` and the Skill tool offers it, call it in the same turn with the current branch name as its target and no `--fix` or `--comment`. It takes a branch, not a SHA, so its `## Code review` section states the range it covered and notes when that differs from the fixed point. It gets neither brief and changes neither axis's findings. Without the tool, say so in the report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec`, verbatim or lightly cleaned, each in its own order (see _Why two axes_), then `## Code review` if it ran. Gather both axes' residual risks under one `## Residual risks` heading, each tagged with its axis. A finding without its probe or quoted line is a residual risk; move it there.

End with a one-line summary: findings per axis and the worst issue _within each axis_ (if any), the residual risk count, then the code review's count if it ran. Never pick one winner across axes or rank the code review against them: that is the reranking the separation exists to prevent.

**Write the ledger.** Number every finding: `S<n>` for Standards, `P<n>` for Spec, `C<n>` for the code review. Residual risks get no id. When the current branch has a ledger ([LEDGER.md](LEDGER.md)), read it, then append the `review` line (with the summary line) and one `finding` line per id, as LEDGER.md says. A branch with no ledger file is not one keel created: create none.

Done when both axes have reported (or the Spec axis is recorded as skipped), the summary line names a count and a worst issue for each axis, every finding has its id, residual risks have none, and a branch with a ledger holds that `review` line and a `finding` line for every id.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the spec asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
