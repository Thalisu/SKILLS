---
type: tool_used
tool: Agent
scope: all
input_match: '^(?=.*"subagent_type":\s*"do-code-review-gate-fixer")(?=.*(reviews/export-notes\.md|## Act on))'
min: 0
max: 0
---
The Gate fixer holds the red block and its brief lines alone: its prompt names neither the Review nor its Act on section.
