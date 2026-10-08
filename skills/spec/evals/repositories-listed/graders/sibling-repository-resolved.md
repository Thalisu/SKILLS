---
type: file_contains
path: ".scratch/*/spec.md"
pattern: '^- (?!.*Home repository)[^:]+: /(?!.*\.\.).+/billing-service/?$'
---
The sibling repository is an entry of its own, and the `../billing-service` the summary gave
relative to the session's repository is written resolved to an absolute path, with no `..` left in
it: a later skill reads the location from another working directory.
