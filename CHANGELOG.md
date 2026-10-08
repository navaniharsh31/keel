# Changelog

All notable changes to keel are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- `keel:build`: implementers and the fixer never edit, skip, loosen or delete existing tests or test config to reach green, and report `BLOCKED:` when a test looks wrong. The implementer brief quotes the spec's hard constraints word for word and forbids narrowing them. The fixer reproduces or refutes each finding before changing code, and the build summary lists refuted findings with their reasons.
- `keel:review`: every finding on both axes carries `file:line` and how it was observed. The Spec axis diffs the test paths against the fixed point to flag weakened tests, and flags tests that assert a constraint violation.
- `keel:review` searches the repo for every standards file (`CODING_STANDARDS.md` and `CONTRIBUTING.md` always, when they exist) and issues both sub-agent calls together, in the foreground. In Claude Code it also runs the bundled `/code-review` over the same diff and reports it under its own `## Code review` section with its own count; other harnesses skip it, and it is not a third axis.
- Ported from Matt Pocock's 2026-10-07 skills: `keel:grill` words each question so "yes" accepts the recommended answer; the `keel:spec` G2 sketch and `keel:tdd` give each seam a one-line note on what it catches and what it misses; `keel:debug` diffs a forced mutation against a pristine copy before trusting the red.
- Router: after a compaction or resume, the agent rebuilds its state from disk (spec and ticket `Status:` lines, `git log`, `git status`) before acting. A few router lines are reworded to stay within 450 words.
- `keel:build`: setting a spec to `Status: done` also adds a header line saying the spec is a historical record and that code, GLOSSARY.md and ADRs win on conflict. The spec template mentions it.
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
