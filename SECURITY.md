# Security policy

keel runs shell scripts on your machine: `hooks/session-start.sh` and `hooks/context-check.sh` on every session in Claude Code (and Codex, if you install its hook), and `scripts/install.sh` when you run it. The hooks only read files (`hooks/flow.md`, `docs/specs/*`, the session transcript) and write a one-line marker file in `$TMPDIR`. They make no network calls.

keel's skills tell the agent to run your project's own commands (tests, typecheck, git). Review what a skill asks for the same way you would any agent action.

## Reporting a vulnerability

Please report privately through [GitHub's private vulnerability reporting](https://github.com/navaniharsh31/keel/security/advisories/new), not in a public issue. You should get a reply within a week. Only the latest release is supported.
