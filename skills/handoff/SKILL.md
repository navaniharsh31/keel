---
name: handoff
description: Write a portable handoff doc so another session or person can continue. Use when moving to a new harness, directory, or colleague, or forking a side task.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows), outside the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for. When a spec is in flight, name the keel skill that resumes it: `keel:build` for a spec at `Status: approved` or `building`, `keel:tickets` for an approved spec with no tickets yet, `keel:spec` when grilling reached G1 but no spec exists.

Reference other artifacts by path or URL instead of duplicating their content: the in-flight `docs/specs/<slug>/spec.md` and its `tickets/` directory, ADRs, `GLOSSARY.md`, commits, diffs. The handoff carries only what lives nowhere else: open questions, the current frontier, the reasoning behind choices not yet written down.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

Done when the file is written, its path is shown to the user, and every artifact it mentions is a path rather than a copy.
