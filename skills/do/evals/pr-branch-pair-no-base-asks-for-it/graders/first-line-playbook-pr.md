---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
Words asking for a pull request that name one branch only still open on the `pr` match, `Playbook: pr`, and never on `integrate` or on `Playbook: none`.
