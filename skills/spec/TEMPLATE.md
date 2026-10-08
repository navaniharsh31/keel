# Spec: <Feature title>

Status: draft
Branch:
Base:

<!-- When keel:build sets `Status: done`, it adds this line below `Base:`: "This spec is a historical record. Code, GLOSSARY.md and ADRs win on conflict." -->

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A numbered list of user stories, proportionate to the feature. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

Cover the behaviours a user would notice. If the list grows past about 15, merge related stories rather than add more.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Keep this to decisions, free of specific file paths and code snippets: they go stale quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts, not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- The seams agreed at G2, and which modules are tested through each
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature, including a pointer to each `prototype/<name>` branch that settled a question.

## Glossary terms used

The `GLOSSARY.md` terms this spec relies on, by name only (the definitions live in `GLOSSARY.md`).
