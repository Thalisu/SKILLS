---
type: llm
criteria: "The run created no file, edited no file, created no worktree and no branch, and made no commit: Ticket 01 still carries both `**Status:**` lines exactly as the scaffold wrote them (its own `ready-for-agent` and the pasted `resolved`), neither removed, rewritten nor set to a single value by the run, Ticket 02 is unchanged and still unclaimed, git status in the fixture shows only the scaffold's own state, and `git worktree list` shows the main checkout alone. Reading the Tickets, the spec, the journey and the tracker file to decide the stop is fine."
---
A stop on a blocker's ambiguous status writes nothing, the blocker's status lines and the blocked Ticket included.
