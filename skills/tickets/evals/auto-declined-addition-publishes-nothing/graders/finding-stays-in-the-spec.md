---
type: file_contains
path: '.scratch/hold-disputed-invoice/spec.md'
pattern: '^- Moved by the run on Ticket 02\b.* at the Plan step: .+\. Belongs to: notifications-service\.$'
---
The finding line is still under the spec's Implementation Decisions, so a later `tickets` run reads
it as uncovered and cuts from it. Read by the script on the file.
