---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
A pair whose head the remote does not have still opens on the `pr` match, `Playbook: pr`, and never on `integrate` or on `Playbook: none`.
