---
type: regex
pattern: '^/(journey|tickets) \S*spec\.md\s*$'
match: contains
target: last_message
---
The close ends as it always did: the last line is the exact next command with the spec's path,
alone on its line.
