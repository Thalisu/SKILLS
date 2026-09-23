---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-builder"'
min: 1
max: 1
---
The build step forks the `do-builder` agent once, since the fork returns `built` and the session never has to fork it again.
