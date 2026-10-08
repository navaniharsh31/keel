# keel

This session runs keel. Every new request gets a lane. Open your reply with it, in one line ("Lane: <name>"), before any tool call.

## Lanes
- **Trivial**: a question, an explanation, a one-line fix, a config tweak. Just do it.
- **Bug**: something broken, throwing, failing, flaky, or slow. Call the Skill tool with "keel:debug".
- **Change**: one clear slice that fits one session. Call the Skill tool with "keel:grill" for a short grilling; G1 then routes to keel:build inline.
- **Feature**: several slices, or the shape is still unclear. Follow the main flow.
- **No repo**: a plan, some writing, or a decision, with no git repo under it. Call the Skill tool with "keel:grill"; it runs stateless.

## Main flow
Keep steps 1–3 in one context window unless a context note says otherwise.
1. **keel:grill**: rounds over the design tree; keel:domain keeps GLOSSARY.md and ADRs current. Ends at **G1**.
2. **keel:spec**: synthesis, no re-interview. **G2** seams, then **G3** spec.
3. **keel:tickets**: tracer-bullet slices with blocking edges. **G4**.
4. **keel:build**: autonomous. A fresh subagent per ticket drives keel:tdd, then review, fixes, commits.
5. **keel:retro**: before the session ends, fix the environment, not the code.

## Stops
Planned stops: G1–G4, build's finish question, and retro's pick. Ask each through AskUserQuestion **on its own**, the only tool call in its message, and act only on its answer. Put what the user decides on (summary, seam sketch, ticket list) in full in every option's `preview`; text beside the call goes unseen. Between them, keep moving without asking. The only unplanned stops: a decision the spec doesn't settle, a one-way door (push, merge to main, delete, migrate real data), a suite you can't turn green, or a dirty tree when a build starts.

## Always
- Read GLOSSARY.md and the relevant ADRs, and speak the glossary's terms.
- Facts are yours to find (dispatch subagents). Decisions are the user's.
- Call the Skill tool with "keel:pr" whenever you write a PR body.
- After compaction or resume, rebuild state from disk before acting: spec and ticket `Status:` lines, `git log`, `git status`.
- Follow any context note. Without the hook, offer keel:handoff past ~100k tokens at a phase boundary.

## Other harnesses
Elsewhere, translate Claude Code's tool names:
- "Call the Skill tool with X": load skill X with your skill loader (Codex: open its SKILL.md; OpenCode: the `skill` tool, names spelled `keel-<name>`).
- AskUserQuestion: your question tool (OpenCode: `question`), with any `preview` printed as text first. Where it can't express the choice (Codex outside Plan mode), ask a numbered plain-text list, recommended option first, and wait.
- The Agent tool: your subagent tool (Codex: `spawn_agent` then `wait_agent`; OpenCode: `task`).
