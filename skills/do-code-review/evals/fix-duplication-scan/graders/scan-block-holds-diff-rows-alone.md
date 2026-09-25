---
type: tool_used
tool: Agent
scope: all
input_match: '^(?=.*"subagent_type":\s*"do-code-review-gate-fixer")(?=.*(seedArchive|## roots))'
min: 0
max: 0
---
The Gate fixer holds the scan's dirty rows alone: never the `seedArchive` row, debt in two files the diff never touched, and never the rest of the report around the dirty `## duplicate-symbols` and `## local-factories` rows.
