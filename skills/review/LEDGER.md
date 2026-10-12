# Ledger

One file per branch keel creates (`feat/<slug>` or `fix/<slug>`), outside the tree. It is never committed, and the main checkout and every worktree share it:

    ledger="$(git rev-parse --git-common-dir)/keel/<branch>"
    mkdir -p "$(dirname "$ledger")"

Append lines, never rewrite them. The merge guard (`hooks/merge-guard.sh`) reads exactly these forms:

- `created <short sha>`: written when the branch is created.
- `review <short sha>: <summary line>`: written by keel:review when it reports.
- `finding <id>: <title>`: one per finding, written by keel:review. Ids are `S<n>` (Standards), `P<n>` (Spec), `C<n>` (code review), unique in the file: a second review continues the numbering.
- `<id> fixed: <commit or what changed>`, `<id> refuted: <evidence>`, `<id> escalated: <the question put to the user>`: one disposition per finding, after its `finding` line. The latest line for an id wins.
- `waived: "<the user's words>"`: only when the user explicitly tells you to skip review. Never write it on your own judgement.

The guard refuses `git merge`, `git branch -d/-D/--delete` and `git push` on a branch whose ledger has no `review` line or a `finding` without a later disposition, unless it has a `waived:` line.

Dispositions:

- **fixed**: apply the reviewer's suggested fix as written, or say in the line why you changed it.
- **refuted**: evidence that disproves the finding (a command and its output, a quoted line). A true fact about nearby code that doesn't disprove it is not a refutation.
- **escalated**: the finding needs a decision the spec doesn't settle; ask the user, then write the outcome as a new line.
- A SMELLS.md judgement call about style may be skipped: `<id> refuted: style, <reason>`. A finding about behaviour is never skipped as minor. A Spec (c) finding is fixed or escalated even when the spec or G1 pinned that behaviour.
