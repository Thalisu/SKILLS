---
type: file_contains
path: ".scratch/*/spec.md"
pattern: '^- [^:(]+ \(Home repository\): /(?!.*\.\.).+/fixture/?$'
---
The Home repository is an entry of its own, marked as such, with its absolute location on this
machine: the fixture the session sits in, whose `.scratch/` holds the Spec. Without it a Ticket
built in the session's own repository has no repository to name.
