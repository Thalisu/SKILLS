---
type: regex
pattern: "git pull --ff-only origin add-total`?.*gh pr merge 42`?\\s*$"
match: contains
target: last_message
---
The Reply's last line names the pull of the developer's head ahead of the merge.
