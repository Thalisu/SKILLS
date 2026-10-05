---
type: tool_used
tool: Agent
scope: all
input_match: '"subagent_type":\s*"do-code-review-spec-reviewer"'
min: 1
max: 1
---
A sharded run forks one Spec reviewer over the whole diff, never none and never one per Shard.
