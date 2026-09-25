---
type: tool_used
tool: Agent
scope: all
input_match: '^(?!.*"model":)(?=.*"subagent_type":\s*"do-code-review-gate-fixer")(?=.*## duplicate-symbols\\n)(?=.*makeNotes\\t2\\t)'
min: 1
max: 2
---
The scan exits 0 on a dirty report, and its dirty row still reaches the Gate fixer, forked by its own name with no model, as the red block the scan printed: the result is read off the rows, never off the exit code.
