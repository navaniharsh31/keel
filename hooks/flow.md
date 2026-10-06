# keel

This session runs the keel SDLC. Before acting on a request, pick its lane and say it in one line ("Lane: feature").

## Lanes
- **Trivial**: a question, an explanation, a one-line fix, a config tweak. Just do it.
- **Bug**: something broken, throwing, failing, flaky, or slow. Call the Skill tool with "keel:debug".
- **Change**: one clear slice that fits one session. Call the Skill tool with "keel:grill" for a short grilling; at G1 it goes straight to keel:build in inline mode.
- **Feature**: several slices, or the shape is still unclear. Follow the main flow.
- **No repo**: a plan, a piece of writing, a decision, with no git repo under it. Call the Skill tool with "keel:grill"; it runs stateless.

## Main flow
Keep steps 1–3 in one unbroken context window (the ~150k rule below is the one exception).
1. **keel:grill**: rounds over the design tree, with keel:domain keeping GLOSSARY.md and the ADRs current. Ends at **G1**.
2. **keel:spec**: synthesis, no re-interview. **G2** seams, then **G3** spec.
3. **keel:tickets**: tracer-bullet slices with blocking edges. **G4**.
4. **keel:build**: autonomous. A fresh subagent per ticket drives keel:tdd; then keel:review, fixes, and commits on the feature branch.
5. **keel:retro**: before the session ends, fix the environment, not the code.

## Stops
Planned stops: the gates G1–G4, build's finish question, and retro's pick. Ask them through AskUserQuestion. Between them, keep moving without asking permission. Unplanned stops are only these: a decision the spec doesn't settle, a one-way door (push, merge to main, delete, migrate real data), a suite you can't turn green, or a dirty working tree when a build starts.

## Always
- Read GLOSSARY.md and the ADRs in the area you're touching, and speak the glossary's terms.
- Facts are yours to find (dispatch subagents). Decisions belong to the user.
- Call the Skill tool with "keel:pr" whenever you write a PR body.
- If the context nears ~150k tokens before the tickets are written, ask the user to /compact at the next phase boundary.

## Other harnesses
The skills speak Claude Code's tool names. On another harness, translate:
- "Call the Skill tool with X": load skill X with your skill loader (Codex: open its SKILL.md; OpenCode: the `skill` tool, names spelled `keel-<name>`).
- AskUserQuestion: your structured question tool (OpenCode: `question`). Where it can't express the choice (Codex outside Plan mode), ask a numbered plain-text list, recommended option first, and wait.
- The Agent tool: your subagent tool (Codex: `spawn_agent` then `wait_agent`; OpenCode: `task`).
