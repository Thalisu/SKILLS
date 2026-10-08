---
type: file_contains
path: ".scratch/*/spec.md"
pattern: '^- (?!.*Home repository)[^:]+: /(?!.*\.\.).+/notification-service/?$'
---
The notification service keeps its entry although the directory at its location is not a git
repository: the line is the one the decisions gave, with `../notification-service` resolved to an
absolute path and no `..` left in it.
