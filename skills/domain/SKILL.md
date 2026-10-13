---
name: domain
description: "Build and sharpen the project's domain language: GLOSSARY.md and ADRs. Use when a term is fuzzy, overloaded, or conflicts with the glossary, or a hard-to-reverse decision should be recorded."
---

# Domain

Sharpen the project's domain model as you design: challenge terms, invent edge-case scenarios, and write terms and decisions down the moment they crystallise.

`GLOSSARY.md` sits at the repo root, ADRs under `docs/adr/` (`0001-event-sourced-orders.md`). Create each lazily, on its first entry.

## During the session

- **Challenge against the glossary.** A term that conflicts with `GLOSSARY.md` gets called out at once: "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"
- **Sharpen fuzzy language.** For a vague or overloaded term, propose a precise canonical one: "By 'account', do you mean the Customer or the User?"
- **Invent concrete scenarios** that probe edge cases and force precise boundaries between concepts.
- **Cross-reference with code.** When the user states how something works, check the code and surface a contradiction: "Your code cancels entire Orders, but you said partial cancellation is possible. Which is right?"
- **Update GLOSSARY.md inline.** Write each term the moment it resolves, never in a batch, in the format of [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md). It holds terms only, no implementation details; those live in `docs/specs/`.

### Offer ADRs sparingly

Offer an ADR only when all three hold: it is **hard to reverse**, **surprising without context** (a future reader will ask why), and **the result of a real trade-off** between genuine alternatives. While grilling, the offer is a question in the next round. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

## Done

- [ ] Every term resolved in the session is in `GLOSSARY.md`, written when it resolved.
- [ ] Every decision that passed all three ADR tests was offered, and each accepted one is written to `docs/adr/`.
