---
name: retro
description: Retrospective that improves the agent's environment (checks, standards, navigation), not the code. Use when a build finishes, a session went sideways, or the user asks for a retro.
---

A **retrospective** suggests improvements to the coding agent's **environment** so future runs go better. The code is out of its reach; the checks, standards, and pointers around the code are its whole subject.

## Steps

### 1. Read the primary sources

Read the session's primary sources: by default the current one (its conversation, the diff since the spec's `Base:`, the review report, every `BLOCKED:` and red suite). If the user names another session, search the session logs on this machine.

Done when you can list every mistake, detour, and slow lookup in the session.

### 2. Find candidates

Look for candidates for improvement in these categories.

- **Navigation**: was the right file easy to find? Are there hidden dependencies between files? Would a **navigation pointer** help? _Use when_ finding a piece of information took long.
- **Automated checks**: could a check (lint, types, tests, filesystem linters) catch an error the agent made? Read the repo's own check command first (its `package.json`/build-tool `lint`/`check` scripts, its CI workflow): a check that exists but sits unwired or silently broken is the finding, its fix is the wiring, and the code it would flag is a follow-up. A repo with no **guardrail** (no pre-commit hook and no CI job running its lint/typecheck/test command) is itself a finding. _Use when_ a check could have caught a mistake, or the repo has no guardrail.
- **Coding standards**: should the **reviewer agent** enforce a new rule, or an existing rule be removed or clarified? _Use when_ the reviewer missed a mistake.
- **Global AGENTS.md / CLAUDE.md**: should steering instructions move to coding standards or checks? _Use when_ the file is large, in the repo or the user's global scope.
- **Tool economy**: could an expensive tool call, or token-hungry custom tooling (CLIs, MCPs), be streamlined? _Use when_ the agent made an expensive call.
- **No-ops**: instructions in steering files that don't change the agent's behaviour. _Use when_ the steering files are large.
- **Information access**: could the agent reach more information (teed dev server logs, read-only third-party access)? _Use when_ a crucial fact was out of reach.

Classify each candidate by where its fix lives:

- **Mechanical → a check.** A fixed syntactic pattern, a banned API, an import shape, a file-location rule gets a deterministic check: a custom rule in the repo's own linter, a pre-commit hook, or a CI job, whichever the repo's language and guardrail make cheapest. A picked check may add files and wire itself into the repo's CI, pre-commit or linter config. Default to building the check over writing the rule.
- **Judgement → `CODING_STANDARDS.md`.** Cross-file consistency, "matches the surrounding style", anything no guardrail could substitute for. Create the file lazily, on the first such rule.
- **Navigation → a `CLAUDE.md` pointer.** `CLAUDE.md` holds pointers only: one line naming a file and when to reach for it.
- **Out of reach → a follow-up.** Product code, tests, dependency pins and edits to existing rules: list each as a follow-up for a new Bug or Change.

Done when every item from step 1 is either a classified candidate or judged not worth fixing.

### 3. List, then pick

Present the candidates most severe first: for each, the evidence from the session, its class, and the exact fix. When step 2 found nothing worth fixing, say so and skip to Done.

- **After a fix** (called from keel:debug, or from keel:build in inline mode): list the candidates and stop. A candidate is applied only when a reply that arrives after the listing names it; then apply it by step 4. A reply received before the listing (a pre-approval in this skill's args included), or one that names nothing ("take your recommendations"), applies nothing.
- **Otherwise** (spec-mode build, or a retro the user asked for): ask through `AskUserQuestion` on its own, with `multiSelect`, at most 4 candidates per question; batch the rest into further questions of the same call. With no `AskUserQuestion`, list the candidates and stop: nothing is applied without a pick.

Done when the candidates are listed and, outside a fix, the user has answered every question.

### 4. Apply

Read [WRITING.md](WRITING.md), then apply every chosen check, standard or pointer. When the fix is a check, run it once and show that it passes on the current tree (and catches the original mistake, where you can reproduce it). Commit as `chore(retro): <what changed>`.

Done when every chosen candidate is applied and committed.

## Done

- [ ] Every candidate a pick (or, after a fix, a later reply) named is applied and committed; nothing else was applied.
