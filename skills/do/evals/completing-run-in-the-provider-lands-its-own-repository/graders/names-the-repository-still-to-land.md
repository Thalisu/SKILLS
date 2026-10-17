---
type: regex
pattern: '^\W*Still to land:\W*orders-service\W*$'
match: contains
target: last_message
---
The Reply names the repositories still to land on a line of its own: `orders-service`, whose Spec
branch this run never touched.
