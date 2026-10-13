# Writing a retro fix

Read this before you write a picked check, standard or pointer.

## Where each fix lives

- **A check** is deterministic: a custom rule in the repo's own linter, a pre-commit hook, or a CI job, whichever the repo's language and guardrail make cheapest. A picked check may add files and wire itself into the repo's CI, pre-commit or linter config.
- **`CODING_STANDARDS.md`** is created lazily, on the first judgement rule.
- **`CLAUDE.md`** holds pointers only: one line naming a file and when to reach for it.

## Writing rules for anything you add

- Lead with a **leading word**: a compact concept the model already knows (*tight*, *red*, *seam*), reused as a token.
- Phrase the target behaviour positively; a prohibition earns its place only as a hard guardrail.
- Hunt **no-ops**: delete any sentence the agent already obeys by default.
- Keep each meaning in a **single source of truth**, and point at the environment (scripts, configs) instead of restating it.

## Implementation vs Review

All work goes through two stages: implementation and review. The implementation agent has the most **context pressure**. They are responsible for exploration, writing code, and debugging failures.

The review agent has the least context pressure: it receives a diff, so no exploration needed. It often does not need to write code or debug.

This means that the review agent should be responsible for imposing coding standards, not the implementation agent.

## Files

- `CLAUDE.md`/`AGENTS.md`: these files are pushed to the context window of any agent working in this repo. They should be used incredibly sparingly, usually only for **navigation pointers** to other files.
- `CODING_STANDARDS.md`: this file is read during review (by keel:review), not implementation. Add **navigation pointers** to docs folders if the standards file gets more than 1,000 lines long.
- Docs: use docs as references files, pointed to by other files. Look for existing docs before writing new ones.
