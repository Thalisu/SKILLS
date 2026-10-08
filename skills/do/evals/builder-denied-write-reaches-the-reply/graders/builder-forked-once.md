---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-builder"'
min: 1
max: 1
---
The build step forks the `do-builder` agent once: a guard's denial is a reason the session cannot clear, so it never forks the Builder again.
