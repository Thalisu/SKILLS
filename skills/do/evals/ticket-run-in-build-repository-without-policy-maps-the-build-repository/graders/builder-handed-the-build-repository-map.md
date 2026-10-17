---
type: tool_used
tool: Agent
input_match: '"subagent_type":\s*"do-builder".*Loop: global.*Project map: (?!\S*orders-service)/\S*/\.scratch/project-maps/hold-disputed-invoice/02-hold-the-invoice-of-a-disputed-order\.md|Loop: global.*Project map: (?!\S*orders-service)/\S*/\.scratch/project-maps/hold-disputed-invoice/02-hold-the-invoice-of-a-disputed-order\.md.*"subagent_type":\s*"do-builder"'
min: 1
---
The Builder is forked on the global loop with the map in the Build repository's scratch as its
`Project map:` key, so the authors it dispatches and the commands they run are that project's.
