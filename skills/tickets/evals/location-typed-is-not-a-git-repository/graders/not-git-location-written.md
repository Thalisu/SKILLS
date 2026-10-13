---
type: file_contains
path: '.scratch/hold-disputed-invoice/spec.md'
pattern: '^- notifications-service: /.+/notifications-service/?\s*$'
---
The spec's Repositories list holds the entry for `notifications-service` at the location typed with
the command, although what sits there is not a git repository: the location is written all the
same, as typed or with its `..` resolved. Read by the script on the file, which held no such line
before the run.
