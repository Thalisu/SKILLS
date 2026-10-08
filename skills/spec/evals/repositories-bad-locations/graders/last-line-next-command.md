---
type: regex
pattern: '^/(journey|tickets) \S*spec\.md\s*$'
match: contains
target: last_message
---
The item the close gained changes nothing below it: the last line is still the exact next command
with the spec's path, alone on its line.
