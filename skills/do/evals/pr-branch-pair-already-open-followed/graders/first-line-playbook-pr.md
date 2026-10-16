---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
Words asking for a pull request from one branch into another open the Reply on the `pr` match, `Playbook: pr`.
