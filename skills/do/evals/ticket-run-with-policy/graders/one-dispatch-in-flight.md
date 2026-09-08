---
type: llm
criteria: "Tests were authored one behaviour at a time: for each behaviour the run dispatched the unit-test-author agent (or, without the Agent tool, applied the inline test-author skill) with the complete dispatch input (behaviour to prove, target, origin, expected red), confirmed the red run for the declared reason, then wrote the implementation and ran the single file, before the next behaviour's test was written. Never several tests written ahead of the code, never two authors in flight at once, and the author was never asked to commit."
---
One dispatch is in flight at a time, never a batch of tests ahead of the code.
