---
type: regex
pattern: '^\W*Landed:\W*billing-service\W*$'
match: contains
target: last_message
---
The Reply of the second stop names the repositories that landed on a line of its own, as the first
stop did: `billing-service`, and no other.
