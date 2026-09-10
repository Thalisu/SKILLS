---
type: llm
criteria: "No Agent tool call appears in the transcript, so neither `global-unit-test-author` nor `global-e2e-test-author` was dispatched, and no Skill call to `test-author` was made. For each behaviour the session wrote the test itself and ran it red before any production change, then the smallest implementation turned it green, and one commit holds the test and the implementation with the `Behaviour:` line in its body."
---
No author is dispatched, and the loop still runs red first.
