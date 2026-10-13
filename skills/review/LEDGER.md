# Ledger

One file per branch keel creates (`feat/<slug>` or `fix/<slug>`), outside the tree. It is never committed, and the main checkout and every worktree share it:

    ledger="$(git rev-parse --git-common-dir)/keel/<branch>"
    mkdir -p "$(dirname "$ledger")"

Append lines, never rewrite them. The merge guard (`hooks/merge-guard.sh`) parses exactly these forms, reading only the lines after the last `created` line:

- `created <short sha>`: written when the branch is created, again if the name is reused.
- `review <short sha>: <summary line>`: written by keel:review when it reports.
- `finding <id>: <title>`: one per finding, written by keel:review. Ids are `S<n>` (Standards), `P<n>` (Spec), `C<n>` (a code review the user asked for), unique in the file: a second review continues the numbering. Residual risks get no line.
- `<id> fixed: <commit or what changed>`, `<id> refuted: <evidence>`, `<id> escalated: <the question put to the user>`: one disposition per finding, after its `finding` line. The latest line for an id wins. Only fixed or refuted closes a finding; an escalated one stays open until the answer is written as a fixed or refuted line.
- `waived: "<the user's words>"`: only when the user explicitly tells you to skip review. Never write it on your own judgement.

Until there is a `review` line and every finding is closed, or a `waived:` line exists, the guard refuses merge, pull of another branch, branch delete, push, `gh pr create` and `gh pr merge`. A line starting with "finding" in any other form also blocks.

Dispositions:

- **fixed**: apply the reviewer's suggested fix as written, or say in the line why not. The regression test gains the finding's failing input. On the changed path, a finding that the code breaks the boundary decision or the spec, or accepts what the input's own rule rejects, is fixed.
- **refuted**: evidence that disproves the finding: a command and its output, or a quoted line. "Pre-existing", "equally loose elsewhere" or "out of scope" refutes a finding only when the same input behaves identically at the fixed point. Proving that takes a run, with the command and output quoted. A fact about other inputs or other code is never a refutation.
- **escalated**: the finding needs a decision the spec doesn't settle. Ask the user; the recommended answer is the fix, and deferral is the option that carries the cost. A reply that takes the recommendation therefore fixes it. Write the answer as the finding's fixed or refuted line.
- A SMELLS.md judgement call about style may be skipped: `<id> refuted: style, <reason>`. A finding about behaviour is never skipped as minor. A Spec (c) finding is fixed or escalated even when the spec or G1 pinned that behaviour.
