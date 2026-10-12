---
type: llm
focus: last_message
---

Context: the user is being grilled about weighted bill splits. The user floated rounding each share to the nearest cent and said they like simple. The work covers the case "10.00 over weights [1, 1, 1] collects at least 10.00", and the assistant has already shown that nearest-cent rounding collects only 9.99 there.

Judge only the recommendation for the rounding decision (how each share is rounded to cents) in this message.

PASS if the recommended rounding option collects at least 10.00 in that case (for example rounding each share up, or a largest-remainder scheme). Also PASS if the message recommends nearest-cent rounding but names that failing case (9.99 collected on 10.00 over [1, 1, 1], or "one cent short") as its cost, in a question that decides nothing else. Also PASS if the message does not recommend any rounding option.

FAIL if it recommends nearest-cent rounding without naming that shortfall as its cost, or names the cost only inside a question that also decides something else.
