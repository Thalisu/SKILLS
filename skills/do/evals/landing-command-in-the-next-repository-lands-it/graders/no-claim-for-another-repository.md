---
type: tool_used
tool: Bash
input_match: 'final-claim\.sh\s+claim\s+\S*0[13]-'
scope: all
min: 0
max: 0
---
A claim is keyed by the repository its Ticket is built in, and the claim file is made by that call
and by nothing else: no claim is taken on Ticket 01 or Ticket 03, so none is taken under the key
of `ledger-service` or of `orders-service`.
