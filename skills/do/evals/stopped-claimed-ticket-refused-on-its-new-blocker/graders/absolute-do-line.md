---
type: regex
pattern: '^\W*/do /\S*/\.scratch/archive-notes/issues/02-count-the-archived-notes\.md\W*$'
match: contains
target: last_message
---
The final message carries `/do` with the blocker's absolute location on a line of its own, read by
the script since the path is machine-dependent; that it comes last is the judge's, in
`command-last-with-no-repository-to-go-to.md`.
