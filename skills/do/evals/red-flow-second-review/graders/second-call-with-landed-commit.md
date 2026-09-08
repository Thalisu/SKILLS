---
type: llm
criteria: "The review was called exactly twice (.git/do-code-review-calls.log holds two lines), both times through the Skill tool with the Ticket's location and main as the landing target and never `fix` nor `--no-fix`. The second call's fixed point is the commit the first call landed (the sha in the first line of .git/do-code-review-landings.log, or a ref equal to it), not the worktree's original base."
---
The second review call takes the landed commit as its fixed point.
