---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
A request to fix a pull request's CI opens on `Playbook: pr`, never on `Playbook: bug-fix`, since the fix is pushed to the pull request and followed to green.
