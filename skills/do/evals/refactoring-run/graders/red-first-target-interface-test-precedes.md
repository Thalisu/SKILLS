---
type: llm
criteria: "In git log on the reviewed branch, the commit that adds the target-interface test (src/status.test.ts, or whatever the run named the test on the extracted status module) comes before every commit that moves structure out of src/notes.ts. The transcript shows that test run and failing for an unresolved import of the new module before any production file was edited, and the dispatch that wrote it declared origin new feature; no test was dispatched with a characterisation origin and no test was written that asserts the current behaviour of src/notes.ts."
---
The red-first test on the target interface precedes any structural change in history.
