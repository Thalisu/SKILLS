---
type: tool_used
tool: Agent
scope: all
input_match: '^(?!.*"model":)(?=.*"subagent_type":\s*"do-code-review-fixer")'
min: 1
---
The orchestrator forks the Fixer by its own name and passes no model, so the Fixer runs on the model and effort its definition picks.
