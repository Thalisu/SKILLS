---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A pair whose base does not exist still opens on the `pr` match, `Playbook: pr`, and never on `integrate` or on `Playbook: none`.
