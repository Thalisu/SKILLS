---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-builder"'
min: 1
max: 1
---
The build step forks the `do-builder` agent once: work for another repository is no reason the session clears, so it never forks the Builder again.
