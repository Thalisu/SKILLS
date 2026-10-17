---
type: regex
pattern: '(?i)consumer.*\bTicket 04 \(built in orders-service\)'
match: contains
target: last_message
---
The pending-debt line for the consumer flows not run names Ticket 04, the Ticket blocked by the one
this run built and built in another repository, as `Ticket 04 (built in orders-service)`.
