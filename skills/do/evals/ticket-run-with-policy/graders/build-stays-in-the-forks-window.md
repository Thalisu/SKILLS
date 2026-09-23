---
type: llm
criteria: "Every edit to a file under src/, bin/ or e2e/ and every commit on do/archive-a-note was made by a `[subagent]` tool call of the Agent call whose subagent_type is `do-builder`, never by the session's own Write, Edit or Bash calls. Before the gate the session ran no unit test and no flow of its own: no `node --test` call outside that fork. What crossed back is lines only, the first reading `built`, then one `behaviour:` and one `build:` line per behaviour of the Plan, one `flow:` line per observable criterion, and a `fallback:` line where something fell back. No diff, no diff summary, no test output and no file's contents appear in the fork's return."
---
The code the Builder wrote and the test output it read stay in its window; only its lines cross back.
