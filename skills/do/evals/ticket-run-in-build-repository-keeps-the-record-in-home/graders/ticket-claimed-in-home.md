---
type: file_contains
path: "../orders-service/.scratch/hold-disputed-invoice/issues/02-hold-the-invoice-of-a-disputed-order.md"
pattern: '^\*\*Status:\*\* claimed\s*$'
---
The claim is written to the Ticket file in the Home repository, where every other run of the
feature reads the Ticket's status.
