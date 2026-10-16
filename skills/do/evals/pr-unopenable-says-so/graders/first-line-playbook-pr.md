---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
A pull request the run cannot follow still opens on the `pr` match, `Playbook: pr`, and never on `Playbook: none`.
