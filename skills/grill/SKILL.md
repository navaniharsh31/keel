---
name: grill
description: Grill the user relentlessly about a plan, feature, or design until you reach shared understanding. Use when starting any non-trivial change, when the user says grill/stress-test/think through, or for plans and writing with no repo.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## Start

In a git repo, call the Skill tool with "keel:domain" now. Its discipline holds for the whole session, so each term lands in `GLOSSARY.md` as it resolves. With no repo, the session is stateless and writes nothing.

## Rounds

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, with lettered options A, B, ... and each option's cost>

➡️ <your recommended option>

---

❓ **Q2** - ...
```

One decision per question: never bundle it with another decision or with the G1 sizing. Letter its options, each with its cost: the case it gets wrong or what it adds. The recommendation must handle every case the work covers.

**Pick the UI per round.** A round of 4 or fewer questions, each a closed choice of 2–4 options, goes through `AskUserQuestion` instead: one entry per question, the recommended option first with "(Recommended)" on its label. Any other round uses the format above. A round never mixes the two.

Each answered round reshapes the tree: settled decisions push the frontier outward and unblock the questions that hung on them. Recompute the frontier and ask the next round. A question that depends on another still open in this round belongs to a _later_ round.

Finding _facts_ is your job, never the user's. When a question needs a fact from the environment (filesystem, tools), dispatch a sub-agent to find it. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

**Prototype detour.** When a question can only be settled by something runnable (does this state model hold up, how should this UI feel), propose a prototype in the round. On a yes, call the Skill tool with "keel:prototype". It is a running exploration too: the questions downstream wait for its verdict.

## G1: aligned?

The lane picked at the start is a first guess; the tree shows the real size. When the frontier is empty, write the **G1 summary**: what was decided, as a numbered list of 10 lines or fewer. It is the user's last look before building, and the spec in inline mode. Ask through `AskUserQuestion` on its own, "Aligned? Next step:", with the summary as every option's `preview` and three options:

- **Spec + tickets**: call the Skill tool with "keel:spec".
- **Build now (single slice)**: call the Skill tool with "keel:build". It runs in inline mode, with the G1 summary as its spec.
- **Not yet, keep grilling**: take what the user says is open, add it to the frontier, and run the next round.

Put the recommended option first with "(Recommended)" on it: *Build now* when the tree is one slice that fits one session, *Spec + tickets* when it is several.

In the no-repo lane, G1 asks only "Aligned?" (*Yes* / *Not yet, keep grilling*). On yes, the session ends with the summary.

## Done

- [ ] The frontier is empty: every branch of the design tree visited, nothing left silently assumed.
- [ ] The user has answered G1 with a next step.
- [ ] In a repo, every term that resolved during the session is in `GLOSSARY.md`.
