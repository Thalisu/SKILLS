---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-(reader|planner|builder|impeccable)"'
scope: all
min: 0
max: 0
---
Every Ticket of the feature reads `resolved`, so the landing command builds nothing: no reader
writes a Digest, no Planner writes a Plan and no Builder is forked.
