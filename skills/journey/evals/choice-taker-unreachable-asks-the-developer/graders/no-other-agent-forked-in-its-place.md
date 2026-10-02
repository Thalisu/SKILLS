---
type: tool_used
tool: Agent
input_match: '^(?!.*"subagent_type":\s*"(prototype|choice-taker)")'
min: 0
max: 0
---
The fixture unlinks `choice-taker`: the session never forks a general agent, or any agent but the
`prototype` a runnable fork gets without the flag, to rule in its place. A call for the
`choice-taker` itself, which the harness refuses, is counted by the grader beside this one.
