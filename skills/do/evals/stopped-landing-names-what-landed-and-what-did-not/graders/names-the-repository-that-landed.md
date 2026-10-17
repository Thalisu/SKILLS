---
type: regex
pattern: '^\W*Landed:\W*billing-service\W*$'
match: contains
target: last_message
---
The Reply of the stop names the repositories of the feature that landed on a line of its own:
`billing-service`, which landed before this run, and not `orders-service`, whose landing stopped.
