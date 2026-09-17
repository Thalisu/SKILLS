---
type: tool_used
tool: Agent
input_match: '^(?!.*"subagent_type":\s*"(choice-taker|do-reader|sketch)")'
min: 0
max: 0
---
No agent is forked in the choice-taker's place: every Agent call names `do-reader` or `sketch`, the forks the run makes before its step, or the choice-taker itself, which no-choice-taker-fork counts. A call with no `subagent_type` falls back to the general agent, so it counts too.
