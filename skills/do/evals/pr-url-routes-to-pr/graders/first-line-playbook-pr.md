---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A request carrying a pull request URL opens on the `pr` match, `Playbook: pr`, and never on `ticket` or on `Playbook: none` for an issue it cannot open.
