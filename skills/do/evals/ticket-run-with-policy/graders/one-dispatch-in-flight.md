---
type: llm
criteria: "Tests were authored one behaviour at a time inside the Builder's window: for each behaviour of the Plan a `[subagent]` Agent call of the `do-builder` fork dispatched the unit-test-author agent with the complete dispatch input (behaviour to prove, relied on by, target, origin, expected red), the red run was confirmed for the declared reason, then the implementation was written and the single file run, before the next behaviour's test was dispatched. Never several tests dispatched ahead of the code, never two authors in flight at once, and no author was asked to commit. The session itself dispatched no test author."
---
One dispatch is in flight at a time in the Builder's window, never a batch of tests ahead of the code.
