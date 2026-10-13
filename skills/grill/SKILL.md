---
name: grill
description: Grill the user relentlessly about a plan, feature, or design until you reach shared understanding. Use when starting any non-trivial change, when the user says grill/stress-test/think through, or for plans and writing with no repo.
---

Interview the user relentlessly until you reach a shared understanding, mapped as a **design tree**: every decision branches into the decisions that hang off it.

## Start

In a git repo, call the Skill tool with "keel:domain" now; its discipline holds all session, so each term lands in `GLOSSARY.md` as it resolves. With no repo, the session is stateless and writes nothing.

## Rounds

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are settled. Ask the whole frontier in one round, each question numbered with your recommended answer, then wait for the answers.

```
❓ **Q1** - **<question title>**: <question body, with lettered options A, B, ... and each option's cost>

➡️ <your recommended option>

---

❓ **Q2** - ...
```

One decision per question: never bundle it with another decision or with the G1 sizing. Letter its options, each with its cost: the case it gets wrong or what it adds. The recommendation must handle every case the work covers.

**Pick the UI per round.** A round of 4 or fewer questions, each a closed choice of 2–4 options, goes through `AskUserQuestion` instead: one entry per question, the recommended option first with "(Recommended)" on its label. Any other round uses the format above, never a mix.

Each answered round pushes the frontier outward. Recompute it and ask the next round; a question that depends on another still open in this round belongs to a _later_ one.

Finding _facts_ is your job, never the user's: dispatch a sub-agent for any fact from the environment, without blocking: only the questions downstream of a running exploration wait. The _decisions_ are the user's: put each to them and wait.

**Prototype detour.** When only something runnable can settle a question (does this state model hold up, how should this UI feel), propose a prototype in the round. On a yes, call the Skill tool with "keel:prototype". Its downstream questions wait for its verdict.

## G1: aligned?

The lane picked at the start is a first guess; the tree shows the real size. When the frontier is empty, write the **G1 summary**: what was decided, in 10 numbered lines or fewer. It is the user's last look before building, and the spec in inline mode. Ask through `AskUserQuestion` on its own, "Aligned? Next step:", with the summary as every option's `preview`:

- **Spec + tickets**: call the Skill tool with "keel:spec".
- **Build now (single slice)**: call the Skill tool with "keel:build", in inline mode with the G1 summary as its spec.
- **Not yet, keep grilling**: add what the user says is open to the frontier and run the next round.

Put the recommended option first with "(Recommended)": *Build now* when the tree is one slice that fits one session, *Spec + tickets* when it is several.

In the no-repo lane, G1 asks only "Aligned?" (*Yes* / *Not yet, keep grilling*). On yes, the session ends with the summary.

## Done

- [ ] The frontier is empty: every branch visited, nothing silently assumed.
- [ ] The user has answered G1 with a next step.
- [ ] In a repo, every term that resolved is in `GLOSSARY.md`.
