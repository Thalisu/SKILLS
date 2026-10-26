---
type: regex
pattern: "^Playbook: pr"
match: contains
target: last_message
---
A request to fix a pull request's CI opens the Reply on the `pr` match, `Playbook: pr`.
