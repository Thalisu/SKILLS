---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-builder"'
min: 2
---
The build step forks the `do-builder` agent at least twice: the first fork returns `stopped` on its spent time budget, and the session forks the next Stretch instead of ending the run.
