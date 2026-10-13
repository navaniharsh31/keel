---
type: regex
target: last_message
pattern: '^[ \t]*(?:[-*][ \t]*)?\*{0,2}\(?([A-D])[).:](?=[^\n]{0,60}[Nn]earest)(?![^\n]*(?:absorb|then add|largest|exact))(?:[^\n]*[Rr]ecommended|[^\n]*\n(?:(?!^-{3})[\s\S])*?^[ \t]*➡️[ \t]*\*{0,2}\1\b)'
flags: m
match: not_contains
---

Fails when the rounding option the round recommends (by the ➡️ letter, or marked recommended) is plain nearest-cent rounding, which collects 9.99 on 10.00 over [1, 1, 1]. Naming that shortfall as its cost does not pass. Nearest-cent with a correction to the total (a share absorbs the difference) is not plain nearest-cent.
