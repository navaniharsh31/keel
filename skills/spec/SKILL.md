---
name: spec
description: Turn the aligned conversation into a spec file under docs/specs/. Use after grilling reaches alignment (G1) on a multi-slice feature, or when the user asks for a spec/PRD.
---

This skill takes the current conversation context and codebase understanding and produces a spec. It is synthesis, not an interview: write down what you already know.

## Steps

### 1. Explore

Explore the repo to understand the current state of the codebase, if you haven't already. Use the glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

Done when you can name the modules the feature touches and the test runner the repo uses (or that it has none).

### 2. Sketch the seams (G2)

Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones. Use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better: the ideal number is one.

**The interface is the test surface.** Callers and tests cross the same seam. If a seam needs testing *past* its interface, the module is the wrong shape: propose the reshape as part of the sketch.

If the repo has no test runner, say so and plan the harness as a prefactor at the agreed seam (it becomes ticket 01).

Write the sketch (each seam, what it tests, why there) and ask **G2** through `AskUserQuestion` on its own, with the sketch as every option's `preview`: *Approve seams* / *Adjust*. On *Adjust*, revise and ask again.

Done when the user picks *Approve seams*.

### 3. Write the spec

Pick a kebab-case `<slug>` for the feature, unused under `docs/specs/`. Write `docs/specs/<slug>/spec.md` from [TEMPLATE.md](TEMPLATE.md) with `Status: draft`, leaving `Branch:` and `Base:` empty (keel:build fills them).

Then check it against the conversation in one pass: walk the grilling session's decisions (every answered round, every G1 summary line, every prototype verdict) and confirm each appears in the spec. Add any that are missing.

Done when every decision from the session appears in the spec.

### 4. Approve (G3)

Write a 5-line summary of the spec and its path, and ask **G3** through `AskUserQuestion` on its own, with the summary as every option's `preview`: *Approve spec* / *Changes needed*. On *Changes needed*, make the changes and ask again.

On *Approve spec*, set `Status: approved`, then call the Skill tool with "keel:tickets" immediately.

## Done

- [ ] `docs/specs/<slug>/spec.md` exists with `Status: approved`.
- [ ] Every decision from the grilling session appears in it.
