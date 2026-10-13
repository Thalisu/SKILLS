---
type: regex
pattern: "^/tickets \\.scratch/hold-disputed-invoice/spec\\.md notifications-service: <[^<>/][^<>]*>\\s*$"
match: contains
target: last_message
---
The Reply carries the `tickets` command on a line of its own, with the Spec's path relative to the
repository, then notifications-service and, in angle brackets, the place where the developer types
its location. No path stands there, since the run knows none.
