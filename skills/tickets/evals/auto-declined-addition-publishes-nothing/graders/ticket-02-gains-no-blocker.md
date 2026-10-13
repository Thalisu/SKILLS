---
type: file_contains
path: '.scratch/hold-disputed-invoice/issues/02-*.md'
pattern: '^\*\*Blocked by:\*\* 01: [^,]+$'
---
Ticket `02` still waits on `01` alone: a blocking edge to a ticket nobody published would hold it
behind an issue that does not exist. Read by the script on the file.
