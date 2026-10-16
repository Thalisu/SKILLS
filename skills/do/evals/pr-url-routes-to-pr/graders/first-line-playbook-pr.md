---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
A request carrying a pull request URL opens on the `pr` match, `Playbook: pr`, and never on `ticket` or on `Playbook: none` for an issue it cannot open.
