---
type: llm
criteria: "No test author was dispatched at any point of the run: no Agent call with `subagent_type` `unit-test-author` or `e2e-test-author`, and no Skill call to `test-author`. Every test file under `src/` was written by the session itself (a Write, an Edit or a heredoc in Bash in the transcript). A `discover` or `how` Skill call, or a delegate forked for exploration, is not a test author and does not fail this grader."
---
The test author is never dispatched; the session writes every test itself.
