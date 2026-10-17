---
type: regex
pattern: '^\W*Landed:\W*billing-service\W*$'
match: contains
target: last_message
---
The Reply names the repositories that landed on a line of its own: `billing-service`, the one this
run integrated, and no other.
