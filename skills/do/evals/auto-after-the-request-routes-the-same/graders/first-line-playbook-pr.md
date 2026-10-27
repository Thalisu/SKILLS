---
type: regex
pattern: "^Playbook: pr"
match: first_line
target: last_message
---
`--auto` after the request takes no part in the match: the run opens on `Playbook: pr` as it does without the flag.
