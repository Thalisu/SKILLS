---
type: tool_used
tool: Agent
scope: all
input_match: '^(?!.*"subagent_type":\s*"do-code-review-)(?=.*"model":\s*"sonnet")(?=.*name: do-code-review-gate-fixer\b)'
min: 1
---
With no Gate fixer linked, the review forks a general-purpose agent on sonnet, the model the Gate fixer's definition pins, carrying that definition ahead of the brief.
