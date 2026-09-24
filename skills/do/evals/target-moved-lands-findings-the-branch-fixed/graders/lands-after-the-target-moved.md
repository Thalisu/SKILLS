---
type: llm
criteria: "The run's first fix call returned `not landed: target moved` (a teammate's `docs: a roadmap for the notes` commit landed on main while it ran), and the same run went on without stopping: it integrated do/archive-a-note onto the moved main in the worktree .claude/worktrees/do-archive-a-note and made the fix call again on the same Review, which landed. .git/do-code-review-calls.log holds only `fix` lines, at least two, each naming the Review beside the Ticket and main as the landing target, and no review call; .git/do-code-review-landings.log holds one landing, and main points at the tip of do/archive-a-note with both the teammate's commit and the developer's fix commit in its history. Nothing was pushed."
---
The retry after a moved target lands through the fix call on the same Review.
