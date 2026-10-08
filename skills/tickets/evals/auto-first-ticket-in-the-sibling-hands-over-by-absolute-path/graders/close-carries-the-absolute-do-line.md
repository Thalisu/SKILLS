---
type: regex
pattern: '^\W*/do --auto /(?:(?!billing-service)\S)*/\.scratch/show-refund-on-order/issues/01-[^/\s]*\.md\W*$'
match: contains
target: last_message
---
The close carries a line of its own that is `/do --auto` followed by the ticket numbered 01 by its
absolute location in the Home repository: a path that starts with `/`, runs through
`.scratch/show-refund-on-order/issues/` and nowhere through `billing-service`. The developer
pastes it into a session of the other repository, where a relative `.scratch/...` path resolves to
nothing. Read by the script on the message itself, since the path is machine-dependent and a judge
can take a relative path for an absolute one; that the line comes last is the judge's, in
`close-ends-on-the-absolute-do-line.md`.
