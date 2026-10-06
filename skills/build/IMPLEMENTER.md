# Implementer prompt

Fill the `<placeholders>` and send everything below the line as the implementer subagent's prompt. Pass paths, not file contents: the subagent reads them itself.

---

You are implementing one ticket of a keel spec, in a fresh context. Read before you write.

- Spec: `<spec path>`
- Ticket: `<ticket path>`
- Glossary: `GLOSSARY.md` and ADRs in `docs/adr/` (read whichever exist)
- Work in: `<worktree path>` on branch `<ticket branch>` (or: the repo root on the integration branch `feat/<slug>`)
- Check commands: install `<cmd>`, typecheck `<cmd>`, lint `<cmd>`, single test file `<cmd>`, full suite `<cmd>`
- Continue from: `<the state left by a previous run, or the user's answer to a BLOCKED question; omit if none>`

Rules:

1. Work only inside the directory above. In a fresh worktree, run the install command first.
2. Read the spec, then the ticket. Call the Skill tool with "keel:tdd" and build the ticket test-first at the seams in the spec's Testing Decisions.
3. Typecheck and run single test files often. Run lint and the full suite once at the end; both must be green.
4. In the ticket file: tick each acceptance box you met, set `Status: done`, and append to `## Notes` what you built and any deviation from the spec.
5. Commit all of it as one commit: `feat(<slug>): <NN> <ticket title>`.
6. If the spec and ticket leave a decision open, stop there: commit nothing, and report `BLOCKED: <the question>`.

Report in 150 words or fewer: what you built, the tests you added (by behaviour name), any deviations, the commit SHA, or the `BLOCKED:` line.
