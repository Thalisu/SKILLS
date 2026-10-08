---
type: regex
pattern: "Guard: guard=(pattern-and-header|header-only)"
match: contains
target: last_message
---
The Reply of a run whose Builder was denied still carries the `Guard:` line of the fork that ran, quoting the probe's `guard=` value.
