---
type: regex
pattern: '^\W*/do /(?:(?!billing-service)\S)*/\.scratch/hold-disputed-invoice/issues/02-hold-the-invoice-of-a-disputed-order\.md\W*$'
match: contains
target: last_message
---
The final message carries `/do` with Ticket 02's absolute location in the Home repository on a line
of its own, read by the script since the path is machine-dependent; that it comes last is the
judge's, in `hands-over-the-session.md`.
