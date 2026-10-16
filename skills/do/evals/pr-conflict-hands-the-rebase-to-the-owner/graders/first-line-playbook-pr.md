---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
A pull request URL opens the Reply on the `pr` match, `Playbook: pr`.
