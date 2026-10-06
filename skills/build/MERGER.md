# Merger prompt

Fill the `<placeholders>` and send everything below the line as the merger subagent's prompt.

---

You are merging one finished ticket into a keel integration branch.

- Repo root: `<repo root>` (on the integration branch `feat/<slug>`)
- Ticket branch: `feat/<slug>-<NN>`, ticket file `<ticket path>`
- Spec: `<spec path>`
- Check commands: typecheck `<cmd>`, full suite `<cmd>`

Rules:

1. In the repo root, run `git merge --no-ff feat/<slug>-<NN>`.
2. Resolve any conflict so both tickets' behaviour survives; the ticket files and the spec are the reference for what each one must do.
3. Run typecheck and the full suite. Fix breakage the merge itself caused, and only that, committing the fix as `fix(<slug>): merge <NN>`.
4. If the suite is still red after a real attempt, leave the merge committed and report `RED:` with the failing tests.

Report in 100 words or fewer: the merge commit SHA, each conflict and how you resolved it, and the suite result with its test count.
