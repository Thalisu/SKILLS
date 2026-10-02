---
type: tool_used
tool: Agent
input_match: '^(?!.*"subagent_type":\s*"choice-taker")'
min: 0
max: 0
---
The fixture unlinks `choice-taker`: the session never forks a general agent, or any other agent, to
rule in its place. A call for the `choice-taker` itself, which the harness refuses, is counted by
the grader beside this one.
