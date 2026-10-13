---
name: retro
description: Retrospective that improves the agent's environment (checks, standards, navigation), not the code. Use when a build finishes, a session went sideways, or the user asks for a retro.
---

A **retrospective** improves the coding agent's **environment** (the checks, standards and pointers around the code) so future runs go better. The code itself is out of its reach.

## Steps

### 1. Read the primary sources

The current session's conversation, diff since the spec's `Base:`, review report, every `BLOCKED:` and red suite; or, if the user names another session, its logs on this machine.

Done when you can list every mistake, detour, and slow lookup in the session.

### 2. Find candidates

- **Navigation**: a file or fact took long to find, or files hide dependencies: a **navigation pointer**?
- **Automated checks**: a check (lint, types, tests, filesystem linters) could have caught a mistake. Read the repo's own check command first (`package.json` or build-tool scripts, the CI workflow): a check that exists but is unwired or silently broken is the finding, its fix is the wiring, and the code it would flag is a follow-up. A repo with no **guardrail** (no pre-commit hook and no CI job running its lint/typecheck/test command) is itself a finding.
- **Coding standards**: the **reviewer agent** missed a mistake: add, remove or clarify a rule.
- **AGENTS.md / CLAUDE.md** (repo or global) grown large: steering that belongs in standards or checks, and **no-ops** (instructions that change nothing).
- **Tool economy**: an expensive call, or token-hungry custom tooling (CLIs, MCPs), to streamline.
- **Information access**: a crucial fact out of reach (teed dev-server logs, read-only third-party access).

Classify each by where its fix lives:

- **Mechanical → a check**: a fixed syntactic pattern, banned API, import shape or file-location rule. Prefer the check to a written rule.
- **Judgement → `CODING_STANDARDS.md`**: cross-file consistency, "matches the surrounding style", anything no guardrail could check.
- **Navigation → a `CLAUDE.md` pointer**: one line naming a file and when to reach for it.
- **Out of reach → a follow-up** for a new Bug or Change: product code, tests, dependency pins and edits to existing rules.

Done when every item from step 1 is a classified candidate or judged not worth fixing.

### 3. List, then pick

List the candidates most severe first, each with its evidence, class and exact fix; or say nothing is worth fixing and skip to Done.

- **After a fix** (called from keel:debug, or from inline keel:build): list and stop. A candidate is applied (step 4) only when a reply that arrives after the listing names it. A reply received before the listing (a pre-approval in this skill's args included), or one that names nothing ("take your recommendations"), applies nothing.
- **Otherwise** (spec-mode build, or a retro the user asked for): ask through `AskUserQuestion` on its own, `multiSelect`, at most 4 candidates per question, the rest in further questions of the same call. Without `AskUserQuestion`, list and stop: nothing is applied without a pick.

Done when the candidates are listed and, outside a fix, the user has answered every question.

### 4. Apply

Read [WRITING.md](WRITING.md), then apply every chosen candidate. Run a new check once: it passes on the current tree and, where reproducible, catches the original mistake. Commit as `chore(retro): <what changed>`.

Done when every chosen candidate is applied and committed.

## Done

- [ ] Every candidate a pick (or, after a fix, a later reply) named is applied and committed; nothing else was applied.
