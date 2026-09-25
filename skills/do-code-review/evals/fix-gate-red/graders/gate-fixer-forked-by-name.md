---
type: tool_used
tool: Agent
scope: all
input_match: '^(?!.*"model":)(?=.*"subagent_type":\s*"do-code-review-gate-fixer")'
min: 1
max: 2
---
The red after the Fixer's commit goes to the Gate fixer, forked by its own name with no model, and never for a third attempt.
