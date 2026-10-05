---
type: tool_used
tool: Agent
input_match: '^(?!.*"subagent_type":\s*"choice-taker")'
min: 0
max: 0
---
The session calls the Agent tool for no other agent in the `choice-taker`'s place. A call with no
`subagent_type` falls back to the general agent, so it counts too. A refused call naming
`choice-taker` itself forks nothing and is how a session may learn the tool is withheld, so it is
left out of the count.
