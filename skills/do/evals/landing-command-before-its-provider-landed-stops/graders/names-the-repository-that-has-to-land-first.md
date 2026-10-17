---
type: regex
pattern: '^\W*Final integration:\W*not started,\W*billing-service\W* has to land first'
match: contains
target: last_message
---
A landing command typed in a repository whose provider has not landed stops in one line naming the
repository that has to land first, off the record's `next_landing=` line.
