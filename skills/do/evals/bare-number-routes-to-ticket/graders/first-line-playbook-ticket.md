---
type: regex
pattern: "^Playbook: ticket"
match: first_line
target: last_message
---
A bare number with no word naming a pull request opens on `Playbook: ticket`, as it did before the `pr` row, and never on `Playbook: pr`.
