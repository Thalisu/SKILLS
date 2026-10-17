---
type: regex
pattern: "Guard: guard=header-only"
match: contains
target: last_message
---
The Reply of a run whose project settings turn hooks off carries the `Guard:` line of the fork that ran, quoting the probe's `guard=header-only` value, although the run is not `--auto`.
