---
type: regex
pattern: "Yours: direction: `?add-total`? .*\\b[0-9a-f]{7,40}\\b.*\\.claude/worktrees/pr-42-"
match: contains
target: last_message
---
The stop hands the kept fixes over on one `Yours: direction:` line naming the head, the sha of each commit kept and the run's worktree they sit in.
