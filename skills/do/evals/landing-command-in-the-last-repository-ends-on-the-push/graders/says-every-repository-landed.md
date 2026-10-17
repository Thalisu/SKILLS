---
type: regex
pattern: '^\W*Every repository of the feature landed\W*$'
match: contains
target: last_message
---
The landing of the last repository left says so on a line of its own. Without it the Reply reads
like any other of the sequence, and the developer goes looking for the next landing command when
there is none.
