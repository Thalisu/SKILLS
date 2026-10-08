---
type: file_contains
path: '.scratch/hold-disputed-invoice/issues/03-*.md'
pattern: '^\*\*Blocked by:\*\*.*\b02\b'
---
The ticket numbered 03 is built in `orders-service` and waits on a ticket built in
`billing-service`: its Blocked by names that blocker by its number in the one folder, `02`. Read by
the script on the file.
