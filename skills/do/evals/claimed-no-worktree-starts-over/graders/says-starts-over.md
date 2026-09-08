---
type: llm
criteria: "The run found the Ticket claimed and no do/archive-a-note worktree in `git worktree list`, said in one line of its first message that it starts over since the worktree is gone, kept the claim (the status line still reads claimed, not rewritten to any other word), and proceeded as a first run: the checklist shown, a new worktree created, the build started. It did not stop, did not ask whether to start over, and did not look for a run-state file."
---
A claimed Ticket with no worktree starts over and says so.
