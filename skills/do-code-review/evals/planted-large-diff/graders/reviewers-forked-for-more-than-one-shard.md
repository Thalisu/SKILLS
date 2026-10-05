---
type: tool_used
tool: Agent
scope: all
input_match: 'Shard: (?!1 of )[0-9]+ of [0-9]+'
min: 1
---
A reviewer was forked for a Shard after the first, which only a diff cut into more than one Shard gets: an unsharded run's briefs carry no `Shard:` line, and the Spec reviewer's carries `Shard manifest:` alone.
