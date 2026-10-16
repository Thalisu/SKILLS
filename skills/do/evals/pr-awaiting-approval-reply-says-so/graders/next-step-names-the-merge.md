---
type: regex
pattern: "[Aa]pprov[^\\n]*gh pr merge 42`?\\s*$"
match: contains
target: last_message
---
The Reply's last line names the approval, then the merge the developer runs once it is given, `gh pr merge 42`.
