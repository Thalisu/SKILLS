---
type: regex
pattern: '^\W*Final integration:\W*not started,\W*billing-service\W* already landed'
match: contains
target: last_message
---
A landing command typed in a repository that already landed says so in one line, naming the
repository off the record's `own=` line: nothing is integrated a second time.
