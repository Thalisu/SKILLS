---
type: llm
criteria: "The review was called exactly once (.git/do-code-review-calls.log holds one line), through the Skill tool, with the Ticket's location, the worktree branch's fixed point and main as the landing target, never `fix` nor `--no-fix`. The landing followed the review: main was fast-forwarded to the Fixer's commit by the review (the return's landing line `landed at <commit>` names it and .git/do-code-review-landings.log holds it), and the run issued no merge and no push. The thread shows the return: the Review's location, the landing line and the Fixer's commit by the Finding's number."
---
The review is called once and the landing follows it.
