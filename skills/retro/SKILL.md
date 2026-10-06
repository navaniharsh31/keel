---
name: retro
description: Retrospective that improves the agent's environment (checks, standards, navigation), not the code. Use when a build finishes, a session went sideways, or the user asks for a retro.
---

A **retrospective** suggests improvements to the coding agent's **environment** so future runs go better. The code is out of its reach; the checks, standards, and pointers around the code are its whole subject.

## Steps

### 1. Read the primary sources

Read the primary sources for the session: by default the current one (its conversation, the diff since the spec's `Base:`, the review report, every `BLOCKED:` and red suite). If the user names another session, search the session logs on this machine.

Done when you can list every mistake, detour, and slow lookup in the session.

### 2. Find candidates

Look for candidates for improvement in these categories.

- **Navigation**: how easy was it for the agent to find the right files? Are there hidden dependencies between files? Would a **navigation pointer** make it easier? _Use when_ the session took a long time to find a piece of information.
- **Automated checks**: are there automated checks that could catch errors the agent made? Linting, typing, tests, filesystem linters? Read the repo's own check command first (its `package.json`/build-tool `lint`/`check` scripts, its CI workflow), so a check that already exists but sits unwired or silently broken is the finding, not a reinvention. A repo with no **guardrail** (no pre-commit hook and no CI job running its lint/typecheck/test command) is itself a finding: an un-linted repo is a standing missed opportunity, not a neutral default. _Use when_ the agent made a mistake an automated check could have caught, or the repo has no guardrail at all.
- **Coding standards**: should the **reviewer agent** be given a new rule to enforce? Should an existing rule be removed or clarified? _Use when_ the reviewer agent failed to catch a mistake.
- **Global AGENTS.md / CLAUDE.md**: are there any steering instructions that should be moved to coding standards (or automated checks) instead? _Use when_ the file is particularly large, in the repo OR the user's global scope.
- **Tool economy**: did the agent make expensive tool calls that could be streamlined? Is there any custom tooling (CLIs, MCPs) that is particularly token-inefficient? _Use when_ the agent made an expensive tool call.
- **No-ops**: look for instructions in steering files that don't modify the agent's behavior. _Use when_ the steering files are large and unwieldy.
- **Information access**: look for opportunities to increase the agent's access to information. Teeing dev server logs, readonly access to third-party services. _Use when_ a crucial piece of information was not available to the agent.

Classify each candidate by where its fix lives:

- **Mechanical → a check.** A fixed syntactic pattern, a banned API, an import shape, a file-location rule gets a deterministic check: a custom rule in the repo's own linter, a pre-commit hook, or a CI job, whichever the repo's language and existing guardrail make cheapest. Default to building the check over writing the rule.
- **Judgement → `CODING_STANDARDS.md`.** Cross-file consistency, "matches the surrounding style", anything no guardrail could ever substitute for. Create the file lazily, on the first such rule.
- **Navigation → a `CLAUDE.md` pointer.** `CLAUDE.md` holds pointers only: one line naming a file and when to reach for it.

Done when every item from step 1 is either a classified candidate or judged not worth fixing.

### 3. Let the user pick

Present the candidates in order of severity, most severe first: for each, the evidence from the session, its class, and the exact fix. Then ask through `AskUserQuestion` on its own, with `multiSelect`, at most 4 candidates per question; batch the rest into further questions of the same call.

Done when the user has answered every question.

### 4. Apply

Apply every chosen candidate. When the fix is a check, run it once and show that it passes on the current tree (and catches the original mistake, where you can reproduce it). Commit as `chore(retro): <what changed>`.

Done when every chosen candidate is applied and committed.

## Writing rules for anything you add

- Lead with a **leading word**: a compact concept the model already knows (*tight*, *red*, *seam*), reused as a token.
- Phrase the target behaviour positively; a prohibition earns its place only as a hard guardrail.
- Hunt **no-ops**: delete any sentence the agent already obeys by default.
- Keep each meaning in a **single source of truth**, and point at the environment (scripts, configs) instead of restating it.

## Reference

### Implementation vs Review

All work goes through two stages: implementation and review. The implementation agent has the most **context pressure**. They are responsible for exploration, writing code, and debugging failures.

The review agent has the least context pressure: it receives a diff, so no exploration needed. It often does not need to write code or debug.

This means that the review agent should be responsible for imposing coding standards, not the implementation agent.

### Files

- `CLAUDE.md`/`AGENTS.md`: these files are pushed to the context window of any agent working in this repo. They should be used incredibly sparingly, usually only for **navigation pointers** to other files.
- `CODING_STANDARDS.md`: this file is read during review (by keel:review), not implementation. Add **navigation pointers** to docs folders if the standards file gets more than 1,000 lines long.
- Docs: use docs as references files, pointed to by other files. Look for existing docs before writing new ones.

## Done

- [ ] Every candidate is either applied (and committed) or explicitly declined by the user.
