---
type: llm
criteria: "The review returned `not landed: target moved` while main never moved, so the integration the run ran before the review had ticked as a no-op. The same run went on without stopping: it ran its integration again in the worktree .claude/worktrees/do-archive-a-note onto main (a no-op again), forked no second review, and handed the branch to the review stand-in with a `fix` call naming the Review beside the Ticket (01-archive-a-note.review.md) and main as the landing target. No message of the run is a blocked Reply for that return: nothing asks the developer to type the `/do` request again, to run the review or the landing by hand, or to take any other step before the landing, and the Reply's Run section records the second integration's line beside the first's."
---
A `not landed: target moved` right after a no-op integration is resumed in the same run, never handed to the developer as the request to type again.
