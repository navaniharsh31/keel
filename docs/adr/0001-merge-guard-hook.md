# Review is enforced by a merge guard, not by prose

keel's skills already told the agent to call keel:review and to account for every finding, and in a benchmark the agent skipped both often enough to ship known bugs. So a PreToolUse hook, the merge guard, refuses `git merge`, `git branch -d/-D` and `git push` on a branch whose ledger lacks a review line or a disposition for every finding. It acts only on branches keel created (they carry a ledger), so a user's own branches are never blocked. It guards the one-way doors rather than "done" because a Stop hook (still out of scope) would fire on every turn, while a merge or push happens once and is where a skipped review does its damage.

## Considered Options

- **Prose and Done checklists only**: rejected; the same instructions were already there and were skipped.
- **A Stop hook that blocks finishing**: rejected; it fires every turn, needs loop protection, and can't tell a mid-flow stop from a finish.
- **Persisted step state for resume**: rejected; a resume reloads the whole conversation, so memory wasn't the gap, verification was.
