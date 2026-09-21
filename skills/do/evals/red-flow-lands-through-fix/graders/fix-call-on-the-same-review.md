---
type: llm
criteria: "The review ran once. .git/do-code-review-calls.log holds two lines, both from the Skill tool: the first is the review call with the Ticket's location, the fixed point, main as the landing target and the gate's command= line; the second, made after the red flow was fixed in the worktree, starts with `fix`, names the Review beside the Ticket (01-archive-a-note.review.md) and main as the landing target. There is no second review call with a Ticket and a fixed point, and `--no-fix` is never passed."
---
The fix of the red flow lands through the fix call on the same Review, never a second review.
