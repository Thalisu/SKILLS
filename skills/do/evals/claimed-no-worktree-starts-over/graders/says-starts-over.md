---
type: llm
criteria: "The run found the Ticket claimed and no do/archive-a-note worktree in `git worktree list`, kept the claim (the status line still reads claimed, not rewritten to any other word), and proceeded as a first run: a new worktree created, the build started. Its final reply's Run section says in one line that the run started over since the worktree was gone, and carries the checklist. The Run section also carries the Plan line: the Plan's location, and any fallback the Planner's return named. It did not stop, did not ask whether to start over, and did not look for a run-state file."
---
A claimed Ticket with no worktree starts over and says so.
