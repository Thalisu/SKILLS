---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"choice-taker"'
min: 0
max: 1
---
Once the `choice-taker` is known to be out of reach, from the Agent tool's own list or from one
refused call, the builder question is not sent to it again.
