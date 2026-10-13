---
type: regex
pattern: '^\W*Still to land:\W*orders-service\W*$'
match: contains
target: last_message
---
The Reply names the repositories still to land on a line of its own: `orders-service` alone.
`billing-service`, which this run just landed, is not on that line.
