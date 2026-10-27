---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
Words naming a pull request with its number open on `Playbook: pr`, never on `Playbook: ticket`.
