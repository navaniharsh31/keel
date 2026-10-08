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
