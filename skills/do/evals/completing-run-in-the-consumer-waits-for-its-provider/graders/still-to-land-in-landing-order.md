---
type: regex
pattern: '^\W*Still to land:\W*billing-service\W*,\W*orders-service\W*$'
match: contains
target: last_message
---
The Reply names both repositories as still to land, in the order the blocking edges give: the
provider `billing-service` before `orders-service`, the session's own, which consumes from it.
