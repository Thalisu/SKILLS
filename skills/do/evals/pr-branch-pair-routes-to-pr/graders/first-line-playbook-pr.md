---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
Words asking for a pull request from one branch into another open on the `pr` match, `Playbook: pr`, and never on `integrate` or on `Playbook: none`.
