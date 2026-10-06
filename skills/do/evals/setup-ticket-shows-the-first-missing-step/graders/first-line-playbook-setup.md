---
type: regex
pattern: "^Playbook: setup"
match: contains
target: last_message
---
A run on a Setup ticket answers `Playbook: setup` on its first line, never `Playbook: ticket`.
