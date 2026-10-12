# Changelog

All notable changes to keel are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- The merge guard: a PreToolUse hook on Bash (`hooks/merge-guard.sh`, plain sh) that refuses `git merge`, `git branch -d/-D/--delete` and `git push` on a branch whose ledger has no review line or a finding without a disposition, unless the ledger has a `waived:` line in the user's own words. The ledger is one file per keel-created branch in the git common dir, shared by the main checkout and every worktree and never committed; its line formats live in `skills/review/LEDGER.md`. Branches without a ledger, other commands and unparseable input pass. `scripts/test-merge-guard.sh` tests it.

### Changed

- `keel:build`: implementers and the fixer never edit, skip, loosen or delete existing tests or test config to reach green, and report `BLOCKED:` when a test looks wrong. The implementer brief quotes the spec's hard constraints word for word and forbids narrowing them. The fixer reproduces or refutes each finding, the bundled code review's included, before changing code, and the build summary lists refuted findings with their reasons.
- `keel:review`: every finding on both axes carries `file:line` and how it was observed. The Spec axis diffs the test paths against the fixed point to flag weakened tests, and flags tests that assert a constraint violation.
- `keel:review` leaves a record and tries to break the change. Its aggregate step numbers every finding (`S<n>` Standards, `P<n>` Spec, `C<n>` code review) and, on a branch with a ledger, appends the `review` line and one `finding` line per finding in `skills/review/LEDGER.md`'s forms, continuing the numbering across reviews; Done requires those lines. On every review, whatever the diff's size, the Spec axis runs break attempts as uncommitted scratch scripts or tests and reports each misbehaviour with its command and output, checks each spec or G1 decision against the cases the work covers (one that fails a covered case is a finding even though the code follows it), always reports code that follows the spec but works badly, names any existing guard or convention covering the same behaviour and whether the change matches it, is looser or is stricter, and lists what it tried when it finds nothing. The Standards axis never labels a behaviour defect a judgement call.
- `keel:review` searches the repo for every standards file (`CODING_STANDARDS.md` and `CONTRIBUTING.md` always, when they exist) and issues both sub-agent calls together, in the foreground. In Claude Code it also runs the bundled `/code-review` on the current branch and reports it under its own `## Code review` section with its own count and the range it covered; other harnesses skip it, and it is not a third axis.
- Ported from Matt Pocock's 2026-10-07 skills: `keel:grill` words each question so "yes" accepts the recommended answer; the `keel:spec` G2 sketch and `keel:tdd` give each seam a one-line note on what it catches and what it misses; `keel:debug` diffs a forced mutation against a pristine copy before trusting the red.
- Router: after a compaction or resume, the agent rebuilds its state from disk (spec and ticket `Status:` lines, `git log`, `git status`) before acting. A few router lines are reworded to stay within 450 words.
- `keel:build`: setting a spec to `Status: done` also adds a header line saying the spec is a historical record and that code, GLOSSARY.md and ADRs win on conflict. The spec template mentions it.
- `keel:grill`: each option carries its cost (the case it gets wrong, or what it adds). The recommendation handles every case the work covers, or names the failing case it accepts as its cost in a question of its own. Each question holds one decision, never bundled with another decision or with the G1 sizing.
- `keel:tdd`: existing tests are probes. One that starts failing or warning under the new behaviour is first checked for a real defect, and the code is fixed if so; an existing test is edited only when its expectation is what the work changes, with a reason in the summary. Where the language allows, the suite runs once with the new warning or error made fatal. Seams also cover near-misses, and Done gains the reason-for-every-edit item.
- `keel:debug`: after Minimise, every bug names its near-misses (cases one step from the repro that must keep their behaviour: for input handling, state identity and performance), and they join the regression test. A search for an existing rule follows: a stricter one is adopted, a looser one is named as a second bug site in the commit message and the retro, not fixed. Phase 6 checks that keel:tdd was loaded and the test went red first. Phase 7 runs lint, typecheck and the full suite, creates `fix/<slug>` with its ledger, and ends in `keel:review` (fixed point the starting branch's `HEAD`; the spec is the bug report, the near-misses and the confirmed hypothesis), with a disposition for every finding and a `fix(<slug>): review findings` commit when anything changed, before the retro and the merge question. Phase 4's tool preferences and perf branch move to `LOOPS.md`.
- `keel:retro` changes only checks, standards and pointers. Product code, tests, dependency pins and existing config are listed as follow-ups for a new Bug or Change. A broken or unwired check is proposed as wiring, never as a cleanup of the code it would flag. Nothing is applied without an `AskUserQuestion` pick; without the tool it lists the candidates and stops. "Nothing worth fixing" is a valid outcome.
- Router: the Bug lane ends in `keel:review`. Without AskUserQuestion, a stop prints its question and options as a numbered list, recommended first, and ends the turn; a reply taking the recommendation answers G1 to G4, and a one-way door goes ahead only on a reply naming it. The other-harness plain-text fallback folds into this rule, and other router lines are reworded to stay within 450 words.
- Spec template: the user-story list is proportionate to the feature and capped at about 15, in place of a "LONG", "extremely extensive" list.

### Fixed

- `keel:build`: a merger whose suite stayed red after a real attempt left the red merge committed on the integration branch. It now undoes the merge (`git merge --abort`, or a reset to the pre-merge SHA), reports `RED:` with the failing tests and whether the merge was kept or undone, and the ticket branch and its worktree are kept for the retry. The integration branch only holds green merges.
- Strict skills clients (skills.sh, `agentskills validate`) skipped `build`, `debug`, `domain`, `pr` and `prototype` because an unquoted `: ` in `description` made their frontmatter invalid YAML. Those descriptions are now quoted, `handoff` no longer sets the non-standard `argument-hint` field, and `scripts/lint.sh` parses every skill's frontmatter with PyYAML's `safe_load` (it fails if PyYAML isn't installed).

## [0.1.0] - 2026-10-07

First public release.

### Added

- The router: a SessionStart hook injects `hooks/flow.md`, which sorts every request into a lane (Trivial, Bug, Change, Feature, No repo) and reports any in-flight spec.
- Twelve skills adapted from Matt Pocock's: `grill`, `domain`, `spec`, `tickets`, `build`, `tdd`, `review`, `pr`, `retro`, `prototype`, `debug`, `handoff`.
- Four human gates (G1 aligned, G2 test seams, G3 spec, G4 tickets), each asked as a structured question with the material in its preview.
- `keel:build`: a fresh implementer subagent per ticket, parallel tickets in worktrees with merger subagents, a two-axis review, a fixer, retro, and a finish choice (merge locally, open a PR, or leave the branch). Resumes from the spec, tickets, and branches after a crash or `/clear`.
- The context note: a hook reads the session's size from the transcript and, at 100k and 140k tokens, tells the agent to offer `keel:handoff` at the next boundary. `keel:handoff` ends with a paste-ready prompt for the next session.
- G4 asks where the build should run, and recommends a fresh session with a one-line prompt to paste after `/clear`.
- Adapters: a Codex plugin manifest and router hook, an OpenCode plugin (1.x and 2.x), and an installer for any harness that reads `.agents/skills`.
- A trigger-correctness eval suite (`evals/`) and hook tests.

### Known gaps

- Codex: the plugin installs and the router hook is wired, but the end-to-end smoke test (lane, skill, gate) hasn't run yet.
- Tier 3 harnesses (Cursor, Gemini CLI, Copilot, Amp, Pi) are best effort and untested.

[Unreleased]: https://github.com/navaniharsh31/keel/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/navaniharsh31/keel/releases/tag/v0.1.0
