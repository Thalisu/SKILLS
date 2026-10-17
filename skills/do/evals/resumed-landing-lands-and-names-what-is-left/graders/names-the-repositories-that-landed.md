---
type: regex
pattern: '^\W*Landed:\W*billing-service,\s*orders-service\W*$'
match: contains
target: last_message
---
The Reply names the repositories that landed on a line of its own, in landing order:
`billing-service`, which landed before the stop, and `orders-service`, which this run landed.
