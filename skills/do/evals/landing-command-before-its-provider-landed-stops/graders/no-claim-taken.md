---
type: tool_used
tool: Bash
input_match: 'final-claim\.sh\s+claim'
scope: all
min: 0
max: 0
---
The run stops before the claim: the claim file is made by that call and by nothing else, so no
call means no claim file under the key of `orders-service`, or of any repository.
