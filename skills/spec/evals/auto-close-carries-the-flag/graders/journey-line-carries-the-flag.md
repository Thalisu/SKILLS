---
type: regex
pattern: '^\W*/journey --auto \S*spec\.md\W*$'
match: contains
target: last_message
---
The close names `/journey --auto <the spec>`, so pasting it keeps the mode at the next skill.
