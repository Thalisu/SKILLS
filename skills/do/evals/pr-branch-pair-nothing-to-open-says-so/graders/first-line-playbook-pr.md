---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A pair with nothing between head and base still opens on the `pr` match, `Playbook: pr`, and never on `integrate` or on `Playbook: none`.
