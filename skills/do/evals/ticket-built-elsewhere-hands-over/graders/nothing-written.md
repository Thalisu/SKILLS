---
type: llm
criteria: "The run created no file, edited no file, created no worktree and no branch, and made no commit, in the fixture and in the sibling folder billing-service alike: Ticket 02 still reads `**Status:** ready-for-agent` and Ticket 01 still reads `resolved`, git status in the fixture shows only the scaffold's own state, and `git worktree list` shows the main checkout alone. Reading the Tickets and the spec, and running the door's script, to decide the stop is fine."
---
A Ticket handed over to its Build repository is not claimed here, so the run the developer starts
there finds it still `ready-for-agent`.
