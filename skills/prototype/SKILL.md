---
name: prototype
description: "Throwaway prototype that answers one design question: does this logic or state model hold up, or what should this UI look like. Use when a grilling question can't be settled on paper."
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

## Pick a branch

Identify which question is being answered, using the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md). Build a single shareable HTML file (free-play buttons plus tabbed guided walkthroughs) that pushes the state machine through cases that are hard to reason about on paper, and that a non-developer can drive.
- **"What should this look like?"** → [UI.md](UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts, so getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Where it lives

Build it in a sibling git worktree, so the grilling session's context and working tree stay untouched:

```sh
git worktree add ../<repo>-proto-<name> -b prototype/<name>
```

Install dependencies there if the prototype needs the app running. When it's ready, put the start command or the file path in front of the user.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious, but name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **Trivial to run.** A UI prototype starts from one command in the project's task runner: `pnpm <name>`, `python <path>`, `bun <path>`, etc. A logic demo is a single HTML file the user double-clicks. Either way, no thinking required to start it.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE, wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Capture it when done.** Once the question is answered:
   - Record the verdict (the question and the answer that settled it) in the grilling conversation, as the settled answer to that frontier question. It ends up in the spec, with any decision-rich snippet inlined as the spec template allows.
   - Commit the prototype on its `prototype/<name>` branch as a **primary source**.
   - Remove the worktree (`git worktree remove ../<repo>-proto-<name>`) and keep the branch.

## Done

- [ ] The question has a verdict the user agreed to, recorded in the conversation.
- [ ] The prototype is committed on `prototype/<name>`, and its worktree is removed.
