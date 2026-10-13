---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-planner"'
min: 1
---
The Plan beside the Ticket was cut from criteria the Ticket no longer holds, so the run forks the
`do-planner` agent again instead of reusing it.
