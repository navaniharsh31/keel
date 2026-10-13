---
name: domain
description: "Build and sharpen the project's domain language: GLOSSARY.md and ADRs. Use when a term is fuzzy, overloaded, or conflicts with the glossary, or a hard-to-reverse decision should be recorded."
---

# Domain

Actively build and sharpen the project's domain model as you design: challenge terms, invent edge-case scenarios, and write the glossary and decisions down the moment they crystallise. (Reading `GLOSSARY.md` for vocabulary is a habit every keel session already has. This skill is for changing the model, not just consuming it.)

## Files

`GLOSSARY.md` sits at the repo root, ADRs under `docs/adr/` (`0001-event-sourced-orders.md`). Create each lazily, when you first have something to write in it.

## During the session

- **Challenge against the glossary.** When the user uses a term that conflicts with `GLOSSARY.md`, call it out immediately: "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"
- **Sharpen fuzzy language.** For a vague or overloaded term, propose a precise canonical one: "You're saying 'account': do you mean the Customer or the User? Those are different things."
- **Discuss concrete scenarios.** Stress-test domain relationships with invented scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.
- **Cross-reference with code.** When the user states how something works, check whether the code agrees, and surface a contradiction: "Your code cancels entire Orders, but you just said partial cancellation is possible. Which is right?"
- **Update GLOSSARY.md inline.** Write each term the moment it resolves, never in a batch, in the format of [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md). It is a glossary and nothing else, devoid of implementation details; specs, scratch notes and implementation decisions live in `docs/specs/`.

### Offer ADRs sparingly

Offer an ADR only when all three are true:

1. **Hard to reverse**: the cost of changing your mind later is meaningful
2. **Surprising without context**: a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off**: there were genuine alternatives and you picked one for specific reasons

If any is missing, skip it. While grilling, the offer is a question in the next round. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

## Done

- [ ] Every term resolved in the session is in `GLOSSARY.md`, written when it resolved.
- [ ] Every decision that passed all three ADR tests was offered, and each accepted one is written to `docs/adr/`.
