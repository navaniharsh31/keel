---
name: grill
description: Grill the user relentlessly about a plan, feature, or design until you reach shared understanding. Use when starting any non-trivial change, when the user says grill/stress-test/think through, or for plans and writing with no repo.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

## Start

If the cwd is a git repo, call the Skill tool with "keel:domain" now. Its discipline stays active for the whole session, so every term that resolves lands in `GLOSSARY.md` as it resolves. With no repo under you, the session is stateless and writes nothing.

## Rounds

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

**Pick the UI per round.** When every question in the round is a closed choice of 2–4 options and the round holds 4 or fewer questions, ask it through `AskUserQuestion` instead: one entry per question, your recommended option first with "(Recommended)" on its label. Every other round uses the plain-text format above. Each round lives wholly in one UI.

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

## Size the work as you go

The lane picked at the start is a first guess; the tree tells you the real size. When the tree turns out to be one slice that fits one session, say so and recommend *Build now* at G1. When a change grows into several slices, say so and recommend *Spec + tickets*.

## Prototype detour

When a frontier question can only be settled by something runnable (does this state model hold up, how should this UI feel), propose a prototype in the round. On a yes, call the Skill tool with "keel:prototype". The prototype is a running exploration: the questions downstream of it wait for its verdict, and the rest of the frontier keeps going.

## G1: aligned?

When the frontier is empty, write the **G1 summary**: what was decided, as a numbered list of 10 lines or fewer. It is the user's last look before building, and the spec in inline mode. Ask through `AskUserQuestion` on its own, "Aligned? Next step:", with the summary as every option's `preview` and three options:

- **Spec + tickets**: call the Skill tool with "keel:spec".
- **Build now (single slice)**: call the Skill tool with "keel:build". It runs in inline mode, with the G1 summary as its spec.
- **Not yet, keep grilling**: take what the user says is open, add it to the frontier, and run the next round.

Put the recommended option first with "(Recommended)" on it: *Spec + tickets* for multi-slice work, *Build now* for a single slice.

In the no-repo lane, G1 asks only "Aligned?" (*Yes* / *Not yet, keep grilling*). On yes, the session ends with the summary.

## Done

The skill is done when all of these hold:

- [ ] The frontier is empty: every branch of the design tree visited, nothing left silently assumed.
- [ ] The user has answered G1 with a next step.
- [ ] In a repo, every term that resolved during the session is in `GLOSSARY.md`.
