---
type: regex
pattern: "gh pr merge 9`?\\s*$"
match: contains
target: last_message
---
The Reply's last line names the merge of the pull request the run opened, `gh pr merge 9`.
