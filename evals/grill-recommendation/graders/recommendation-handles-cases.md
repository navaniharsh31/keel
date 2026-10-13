---
type: regex
target: last_message
pattern: '^[ \t]*(?:[-*][ \t]*)?\*{0,2}(?:[Oo]ption[ \t]+(?=[A-Da-d]\b)|\(?(?=[A-Da-d](?:[).:]|\*\*[ \t]*[-:.)])))([A-Da-d])(?=[^\n]{0,60}(?:[Nn]earest|[Cc]losest))(?![^\n]*(?:absorb|then add|largest|exact))(?:[^\n]*[Rr]ecommended|[^\n]*\n(?:(?!^-{3})[\s\S])*?^[ \t]*➡️(?:(?!\b[A-Da-d]\b)[^\n])*\b\1\b)'
flags: m
match: not_contains
---

Fails when the rounding option the round recommends (by the first option letter after ➡️, or marked recommended) is plain nearest-cent (or closest-cent) rounding, lettered `A)`, `(a)` or `Option A`, which collects 9.99 on 10.00 over [1, 1, 1]. Naming that shortfall as its cost does not pass. Nearest-cent with a correction to the total (a share absorbs the difference) is not plain nearest-cent.
