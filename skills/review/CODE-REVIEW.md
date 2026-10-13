# Bundled code review

Read by keel:review only when the user asked for Claude Code's bundled `/code-review`.

If the Skill tool offers it, call it in the same turn as the two axes, with the current branch name as its target (it takes a branch, not a SHA) and no `--fix` or `--comment`. Its report goes under `## Code review`, stating the range it covered and noting any difference from the fixed point. It gets neither brief and changes neither axis's findings. Its findings get `C<n>` ids. Without the tool, say so in the report.
