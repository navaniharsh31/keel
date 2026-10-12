# Ledger

One file per branch keel creates (`feat/<slug>` or `fix/<slug>`), outside the tree. It is never committed, and the main checkout and every worktree share it:

    ledger="$(git rev-parse --git-common-dir)/keel/<branch>"
    mkdir -p "$(dirname "$ledger")"

Append lines, never rewrite them. The merge guard (`hooks/merge-guard.sh`) reads exactly these forms:

- `created <short sha>`: written when the branch is created. A branch created again under the same name appends a new one, and the guard reads only the lines after the last `created` line.
- `review <short sha>: <summary line>`: written by keel:review when it reports.
- `finding <id>: <title>`: one per finding, written by keel:review. Ids are `S<n>` (Standards), `P<n>` (Spec), `C<n>` (code review), unique in the file: a second review continues the numbering.
- `<id> fixed: <commit or what changed>`, `<id> refuted: <evidence>`, `<id> escalated: <the question put to the user>`: one disposition per finding, after its `finding` line. The latest line for an id wins. Only a fixed or refuted line closes a finding: an escalated one stays open until the user's answer is written as a new fixed or refuted line (or a `waived:` line).
- `waived: "<the user's words>"`: only when the user explicitly tells you to skip review. Never write it on your own judgement.

The guard refuses `git merge`, `git pull` of another branch, `git branch -d/-D/--delete`, `git push`, `gh pr create` and `gh pr merge` on a branch whose ledger has no `review` line, a `finding` without a later fixed or refuted line, or a line starting with "finding" in any other form, unless it has a `waived:` line. It backstops skipped steps, not an adversary, so it fails open on spellings it can't map to a branch.

Dispositions:

- **fixed**: apply the reviewer's suggested fix as written, or say in the line why you changed it.
- **refuted**: evidence that disproves the finding (a command and its output, a quoted line). A true fact about nearby code that doesn't disprove it is not a refutation.
- **escalated**: the finding needs a decision the spec doesn't settle; ask the user, then write the answer as the finding's fixed or refuted line.
- A SMELLS.md judgement call about style may be skipped: `<id> refuted: style, <reason>`. A finding about behaviour is never skipped as minor. A Spec (c) finding is fixed or escalated even when the spec or G1 pinned that behaviour.
