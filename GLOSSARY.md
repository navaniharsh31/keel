# keel

A Claude Code plugin that runs a gated SDLC for solo devs: it routes itself through grilling, spec, tickets, build, review, and retro.

## Flow

**Lane**:
The size class the router assigns a request before acting: Trivial, Bug, Change, Feature, or No repo. Each lane names its entry skill.
_Avoid_: mode, track

**Main flow**:
The Feature lane's path: grill, spec, tickets, build, retro.

**Gate**:
One of the four planned human stops, G1 (aligned), G2 (seams), G3 (spec), G4 (tickets), each asked through a structured question.
_Avoid_: checkpoint, approval step

**Unplanned stop**:
A stop outside a gate that keel allows: an unsettled decision, a one-way door, an unfixable red suite, or a dirty tree when a build starts.

**Router**:
`hooks/flow.md`, injected at session start, which picks the lane and maps the flow.

**In flight**:
A spec whose status is `approved` or `building`; the session-start hook reports each one.

## Work items

**Spec**:
The file `docs/specs/<slug>/spec.md` that records one feature's problem, solution, user stories, and decisions. Its header carries the state.
_Avoid_: PRD, plan

**Ticket**:
One tracer-bullet unit of a spec, one file under `docs/specs/<slug>/tickets/`, declaring its blocking edges.
_Avoid_: issue, task, story

**Frontier**:
The set of items that can be worked now: in grilling, the questions whose prerequisites are settled; in a build, the ready tickets whose blockers are done.

## Build

**Integration branch**:
The `feat/<slug>` branch every ticket of a spec lands on.

**Implementer**:
The fresh subagent that builds one ticket test-first.

**Merger**:
The subagent that folds one ticket branch into the integration branch and gets the suite green, or undoes a merge that stays red.

**Fixer**:
The subagent that applies review findings after every ticket is done.

**Inline mode**:
keel:build without a spec, for the Change lane: the session builds the agreed slice itself, with the G1 summary as its spec.

## Evidence

**Boundary decision**:
The one rule a bug fix must enforce, settled before the fix: the rule itself, the cases it accepts and rejects, and the existing rule it adopts. It is the spec the fix's review checks against.
_Avoid_: scope note, assumption

**Near-miss**:
A case one step from a bug's repro that the boundary decision rules on (rejected, still the same object, still fast). Each one becomes a case in the regression test.
_Avoid_: edge case, negative test

**Residual risk**:
A concern a reviewer raised that no probe or quoted line proved, or a style point on lines the diff didn't touch. It is listed in the review report, never given an id or a disposition.
_Avoid_: minor finding, nit

**Disposition**:
The one recorded outcome of a review finding: fixed, refuted with evidence, or escalated to the user.
_Avoid_: triage, resolution

**Ledger**:
The per-branch file keel keeps outside the tree, recording that review ran and each finding's disposition. A branch keel created always has one.
_Avoid_: state file, progress log

**Merge guard**:
The hook that refuses a one-way git door (merge, branch delete, push) on a branch whose ledger lacks a review or a disposition.
_Avoid_: gate (gates are human stops)
