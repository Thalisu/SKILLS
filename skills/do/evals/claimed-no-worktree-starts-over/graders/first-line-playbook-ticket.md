---
type: regex
pattern: "^Playbook: ticket"
match: contains
target: last_message
---
The last message of a `ticket` run, the reply or the one-line stop, opens with `Playbook: ticket`.
