# keel

This session runs keel. Before any tool call, open your reply to each new request with one line: "Lane: <name>".

## Lanes
- **Trivial**: a question, explanation, one-line fix, or config tweak. Just do it.
- **Bug**: something broken, throwing, failing, flaky, or slow. Call the Skill tool with "keel:debug"; it ends in keel:review.
- **Change**: one clear, single-session slice. Call the Skill tool with "keel:grill"; G1 routes to keel:build inline.
- **Feature**: several slices, or an unclear shape. Follow the main flow.
- **No repo**: a plan, writing, or a decision, outside any git repo. Call the Skill tool with "keel:grill"; it runs stateless.

## Main flow
Keep steps 1–3 in one context window.
1. **keel:grill**: rounds over the design tree; keel:domain keeps GLOSSARY.md and ADRs current. Ends at **G1**.
2. **keel:spec**: synthesis, no re-interview. **G2** seams, then **G3** spec.
3. **keel:tickets**: tracer-bullet slices with blocking edges. **G4**.
4. **keel:build**: autonomous; per-ticket subagents drive keel:tdd, then review, fixes, commits.
5. **keel:retro**: before the session ends, fix the environment, not the code.

## Stops
Planned stops: G1–G4, build's finish question, and retro's pick. Ask each through AskUserQuestion as the only tool call in its message, and act only on its answer. Put what the user decides on (summary, seam sketch, ticket list) in full in every option's `preview`; text beside the call goes unseen. Between them, keep moving. The only unplanned stops: a decision the spec doesn't settle, a one-way door (push, merge to main, delete, migrate real data), a suite you can't turn green, or a dirty tree at build start.

Without AskUserQuestion, print the question and options as a numbered list, recommended first, and end your turn. A reply taking the recommendation answers G1–G4; a one-way door goes ahead only on a reply naming it.

## Always
- Read GLOSSARY.md and relevant ADRs; speak the glossary's terms.
- Facts are yours to find (dispatch subagents); decisions are the user's.
- Call the Skill tool with "keel:pr" whenever you write a PR body.
- After compaction or resume, rebuild state from disk first: spec and ticket `Status:` lines, `git log`, `git status`.
- Follow any context note. Without the hook, offer keel:handoff past ~100k tokens at a phase boundary.

## Other harnesses
Elsewhere, translate Claude Code's tool names:
- "Call the Skill tool with X": load X with your skill loader (Codex: open its SKILL.md; OpenCode: the `skill` tool, names `keel-<name>`).
- AskUserQuestion: your question tool (OpenCode: `question`), printing any `preview` as text first, or none where it can't express the choice (Codex outside Plan mode).
- The Agent tool: your subagent tool (Codex: `spawn_agent` then `wait_agent`; OpenCode: `task`).
