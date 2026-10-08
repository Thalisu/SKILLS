---
type: file_contains
path: '.scratch/hold-disputed-invoice/issues/01-*.md'
pattern: '^\*\*Build repository:\*\* orders-service\s*$'
---
The published ticket numbered 01 carries a bold header line of its own naming the one repository it
is built in, `orders-service`, by the name the Spec's Repositories section gives that entry and with no
path and no mark after it. `do`'s door reads this line to decide whether the session's repository is the one to build
in, so a ticket published without it is one the door cannot place. Read by the script on the file.
