---
type: regex
pattern: "gh pr merge 42`?\\s*$"
match: contains
target: last_message
---
The Reply's last line names the merge the developer runs, `gh pr merge 42`.
