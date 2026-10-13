# Ledger

One file per branch keel creates (`feat/<slug>` or `fix/<slug>`), outside the tree, never committed, shared by every worktree: `"$(git rev-parse --git-common-dir)/keel/<branch>"`. A ledger is made only by `sh <this directory>/new-branch.sh <branch> [<start-point>]`, which creates and switches to the branch and writes its `created` line, refusing an existing branch.

Append lines, never rewrite them. The merge guard (`hooks/merge-guard.sh`) parses exactly these forms after the last `created` line:

- `created <short sha>`: written by new-branch.sh, again on a reused name.
- `review <short sha>: <summary line>` and `finding <id>: <title>` (one per finding): by keel:review. Ids are `S<n>` (Standards), `P<n>` (Spec), `C<n>` (a code review the user asked for), unique in the file: a second review continues the numbering. Residual risks get no line.
- `<id> fixed: <commit or what changed>`, `<id> refuted: <evidence>`, `<id> escalated: <the question put to the user>`: one disposition per finding, after its `finding` line. The latest line for an id wins. Only fixed or refuted closes a finding; an escalated one stays open.
- `waived: "<the user's words>"`: only when the user explicitly tells you to skip review.

Until a `review` line exists and every finding is closed, or a `waived:` line exists, the guard refuses merging, pulling, deleting, pushing or opening a PR for the branch. A "finding" line in any other form also blocks.

Dispositions:

- **fixed**: the reviewer's suggested fix, applied as written, or the line says why not. The regression test gains the finding's failing input. On the changed path, a finding that the code breaks the boundary decision or the spec, or accepts what the input's own rule rejects, is fixed.
- **refuted**: evidence that disproves the finding: a command and its output, or a quoted line. "Pre-existing", "equally loose elsewhere" or "out of scope" refutes a finding only when the same input behaves identically at the fixed point, proved by a run with the command and output quoted. A fact about other inputs or other code is never a refutation.
- **escalated**: a decision the spec doesn't settle. Ask the user, recommending the fix; deferral is the option that carries the cost, so a reply taking the recommendation fixes it. Write the answer as the finding's fixed or refuted line.
- A SMELLS.md judgement call about style may be skipped: `<id> refuted: style, <reason>`. A behaviour finding is never skipped as minor. A Spec (c) finding is fixed or escalated even when the spec or G1 pinned that behaviour.
