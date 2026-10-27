---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A pull request the run cannot follow still opens on the `pr` match, `Playbook: pr`, and never on `Playbook: none`.
