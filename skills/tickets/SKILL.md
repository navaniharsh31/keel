---
name: tickets
description: Split an approved spec into tracer-bullet vertical-slice tickets with blocking edges. Use right after a spec is approved, or when the user asks to break work into tickets.
---

# Tickets

Break an approved spec into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it. The tickets form a **task graph**, not a list of steps.

## Steps

### 1. Read the spec and look for prefactoring

Read `docs/specs/<slug>/spec.md` (the one just approved, or the path the user passed). If you haven't explored the code the spec touches, do so now. Ticket titles and descriptions use the glossary vocabulary and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change." Prefactor tickets come first.

Done when every user story in the spec has been read and every prefactor you found is listed.

### 2. Draft vertical slices

Break the work into **tracer bullet** tickets.

<vertical-slice-rules>

- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests): vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first
- When the repo has no test runner, ticket 01 is the harness prefactor at the seam agreed at G2

</vertical-slice-rules>

Give each ticket its **blocking edges**: the other tickets that must complete before it can start. A ticket with no blockers can start immediately. Draw the edges only where one ticket genuinely gates another: every edge you skip is parallelism keel:build gets for free.

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is one mechanical change (rename a column, retype a shared symbol) whose **blast radius** fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Sequence it as **expand–contract** instead of forcing it into a tracer bullet. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own ticket blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in a ticket blocked by every migrate batch.

Done when every user story maps to at least one ticket and every ticket has its edges declared.

### 3. Approve (G4)

Present the breakdown as a numbered list. For each ticket, show:

- **Title**: short descriptive name
- **Type**: `slice`, `prefactor`, `expand`, `migrate`, or `contract`
- **Blocked by**: which other tickets (if any) must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Under the list, give a one-line ASCII **task graph** showing what can run in parallel (`01 → {02, 03} → 04`), and the story → ticket mapping (`1,2 → 02; 3 → 03`).

Then ask **G4** through `AskUserQuestion`: *Approve* / *Too coarse* / *Too fine* / *Fix edges* (the user adds detail through "Other"). On anything but *Approve*, revise and ask again.

Done when the user picks *Approve*.

### 4. Write the tickets

Write one file per ticket under `docs/specs/<slug>/tickets/<NN>-<ticket-slug>.md`, numbered from `01` in dependency order (blockers first), from [TEMPLATE.md](TEMPLATE.md). One ticket per file, never a single combined file.

Keep tickets free of specific file paths and code snippets: they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

Then call the Skill tool with "keel:build" immediately. The autonomous phase starts here.

## Done

- [ ] Every user story in the spec is covered by at least one ticket (the mapping was in the G4 message).
- [ ] Every ticket file exists with `Status: ready`, its `Type:`, and its `Blocked by:` edges.
