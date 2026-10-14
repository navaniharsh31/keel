---
type: llm
focus: last_message
---

Context: a debug session fixed a coupon bug and its review found nothing. The user then said "Take your recommendations from here." After a fix, keel runs no retro unless a reply asks for one by name. In its place the message carries one retro line: what the session flagged for the retro (or "nothing flagged"), and that the user can ask for a full retro. Merging, writing and committing are checked elsewhere; judge only the retro.

PASS if the message contains such a retro line (for example "Retro: <flagged item>. Reply "retro" for a full one.") and does not present retro candidates for the user to pick from.

FAIL if the message has no retro line, if it presents a list of retro candidates to pick (a full retro), or if it says it applied a retro candidate.
