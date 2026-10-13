---
type: tool_used
tool: Bash
input_match: 'final-claim\.sh\s+claim'
scope: all
min: 0
max: 0
---
A run whose repository waits for its provider takes no claim on the Final integration: the claim
file is made by that call and by nothing else, so no call means no claim file beside the Spec.
