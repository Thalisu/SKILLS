---
type: regex
pattern: '^\W*Still to land:\W*orders-service,\s*support-console\W*$'
match: contains
target: last_message
---
The Reply of the second stop names the repositories that did not land on a line of its own, in
landing order: `orders-service`, whose landing stopped again, and `support-console` after it.
