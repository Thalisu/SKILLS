---
type: tool_used
tool: Agent
input_match: '^(?=.*"subagent_type":\s*"choice-taker")(?=.*Caller: tickets)'
min: 1
max: 1
---
The approval is forked to the `choice-taker` once, on a brief that names `tickets` as its caller.
Read by the script on the whole brief, since the judge is shown only the head of a call.
