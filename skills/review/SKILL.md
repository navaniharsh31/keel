---
name: review
description: Two-axis review (Standards and Spec) of a diff against a fixed point, run as parallel sub-agents. Use after building, or when the user asks to review a branch, PR, or changes since X.
---

Two-axis review of the diff between `HEAD` and a fixed point:

- **Standards**: does the code conform to this repo's documented coding standards?
- **Spec**: does the code faithfully implement the originating spec?

Both axes run as **parallel sub-agents** so they don't pollute each other's context, then this skill aggregates their findings. In Claude Code it also runs the bundled `/code-review` over the same diff and reports it in its own section; that is not a third axis.

## Process

### 1. Pin the fixed point

Use the fixed point the caller or user gave (a commit SHA, branch name, tag, `main`, `HEAD~5`, etc.). If none was given, use the `Base:` SHA of the spec under `docs/specs/` whose `Branch:` matches the current branch. If there is no such spec, ask for it.

Capture the diff command once: `git diff <fixed-point>...HEAD` (three-dot, so the comparison is against the merge-base). Also note the list of commits via `git log <fixed-point>..HEAD --oneline`.

Before going further, confirm the fixed point resolves (`git rev-parse <fixed-point>`) and the diff is non-empty. A bad ref or empty diff should fail here, not inside two parallel sub-agents.

### 2. Identify the spec source

Look for the originating spec, in this order:

1. What the caller passed: a spec path, or (inline mode) the G1 summary.
2. The `docs/specs/<slug>/` whose `Branch:` matches the current branch, or whose slug matches the branch name: its `spec.md` plus every ticket file under `tickets/`.
3. If nothing is found, ask the user where the spec is. If they say there isn't one, the **Spec** sub-agent will skip and report "no spec available".

### 3. Identify the standards sources

Search the repo for every file that documents how code should be written. When `CODING_STANDARDS.md` or `CONTRIBUTING.md` exists, it must be on the list. On top of those, the Standards axis always carries the **smell baseline** in [SMELLS.md](SMELLS.md).

### 4. Spawn both sub-agents in parallel

Issue both sub-agent calls together, in the foreground, and aggregate the reports they return.

**Standards sub-agent prompt** should include:

- The full diff command and commit list.
- The list of standards-source files you found in step 3, **plus the full text of SMELLS.md** pasted in (the sub-agent has no other access to it).
- The brief: "Report, per file/hunk where relevant, (a) every place the diff violates a documented standard: cite the standard (file + the rule); and (b) any baseline smell you spot: name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard breaches can be hard; SMELLS.md's rules govern the baseline; a behaviour defect is never labelled a judgement call, whichever rule it surfaced under. Skip anything tooling enforces. Give each finding its `file:line` and how you observed it (the hunk you read, or the command you ran and its output). Under 400 words."

**Spec sub-agent prompt** should include:

- The diff command and commit list.
- The spec and ticket paths, or the G1 summary text in inline mode.
- The brief: "Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the diff that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong, including code that follows the spec but works badly (never optional: report it even when the spec or G1 pinned that behaviour); (d) weakened tests: run `git diff <fixed-point> -- <test paths>` and flag every existing test or test config that was skipped, loosened, deleted, or edited to pass; (e) tests that assert a violation of a spec constraint; (f) break attempts, whatever the diff's size: pick the inputs or call sequences most likely to make the change misbehave (just past a boundary, malformed, out of order, the path the change didn't touch), run each as a scratch script or test you don't commit and delete afterwards, and report every misbehaviour with its command and output; (g) decisions that don't hold: check each decision in the spec or G1 summary against the cases the work covers, not only whether the code conforms to it; a decision that fails a covered case is a finding even though the code follows it. Where an existing guard or convention in the repo covers the same behaviour, name it (`file:line`) and say whether the change matches it, is looser, or is stricter. Quote the spec line for each finding, and give its `file:line` and how you observed it (the hunk you read, or the command you ran and its output). If you find nothing, list what you tried; never invent a finding to fill the report. Under 400 words."

If the spec is missing, skip the Spec sub-agent and note this in the final report.

**Bundled code review (Claude Code only).** When the Skill tool offers the bundled `code-review`, call it in the same turn with the current branch name as its target and no `--fix` or `--comment`. This skill only reports. The code review takes a branch, not a SHA, so its `## Code review` section states the range it covered and notes when that differs from the fixed point. Other harnesses skip it and note "no bundled code review" in the final report. It gets neither axis brief and changes neither axis's findings.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned, then the bundled review (if it ran) under `## Code review`. Keep each section's findings separate and in its own order, because the two axes are deliberately separate (see _Why two axes_).

End with a one-line summary: total findings per axis, and the worst issue _within each axis_ (if any), then the code review's own count. Name a worst issue per axis rather than a single winner across axes: a cross-axis winner is the reranking the separation exists to prevent, and the code review's findings are not ranked against either axis.

**Write the ledger.** Number every finding in the report: `S<n>` for Standards, `P<n>` for Spec, `C<n>` for the code review. When the current branch has a ledger ([LEDGER.md](LEDGER.md)), read it first, then append the `review` line (with this summary line) and one `finding` line per finding, numbered and formed as LEDGER.md says. A branch with no ledger file is not one keel created: create none.

Done when both axes have reported (or the Spec axis is recorded as skipped), the code review has reported or is recorded as skipped, the summary line names a count and a worst issue for each axis and a count for the code review, every finding has its id, and a branch with a ledger holds that `review` line and a `finding` line for every id.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the spec asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.
