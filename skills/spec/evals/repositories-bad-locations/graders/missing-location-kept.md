---
type: file_contains
path: ".scratch/*/spec.md"
pattern: '^- (?!.*Home repository)[^:]+: /(?!.*\.\.).+/billing-service/?$'
---
The billing service keeps its entry although nothing exists at its location: the line is the one
the decisions gave, with `../billing-service` resolved to an absolute path beside the Home
repository and no `..` left in it. A Spec that drops the entry, or points it somewhere that does
exist, is no longer what was decided.
