---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A pull request URL opens the Reply on the `pr` match, `Playbook: pr`.
