---
type: llm
focus: trace
---

Look only at the assistant's own messages, ignoring system, hook, and tool-result text (the injected keel router contains the example "Lane: feature", which does not count).
PASS if the assistant states the lane of this request as Feature.
FAIL if it states a different lane or none.
