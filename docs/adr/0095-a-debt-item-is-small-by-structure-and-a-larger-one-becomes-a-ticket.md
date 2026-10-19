# A debt item is small by structure, and a larger one becomes a Ticket

Only small items are handed to a Fixer, and small is a structure, not an estimate: the fix is one
behaviour, proven by one test, in one commit, with no Design fork, in files its `Fix:` line names.
An item that is larger is never cut into several `Act on` Findings: it lands in `Consider` marked
`too big for a Fixer`, and the skill points at `/tickets` to add it to the open feature (ADR 0083).
The token bands of ADR 0016 measure a `do` session's peak context over a whole Ticket and say
nothing about what a Fixer can hold, and the pieces of a split item touch the same files, so the
Waves would serialize them and a piece landed alone would leave the code half changed.
