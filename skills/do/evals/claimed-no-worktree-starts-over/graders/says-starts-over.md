---
type: llm
criteria: "The run found the Ticket claimed and no do/archive-a-note worktree in `git worktree list`, kept the claim (the status line still reads claimed, not rewritten to any other word), and proceeded as a first run: a new worktree created, the build started. Its final reply's Run section says in one line that the run started over since the worktree was gone, and carries the checklist. The Run section also carries the Plan line, naming the Plan beside the Ticket and saying it was reused: the run forked no `do-planner` and no `do-reader`, since the fixture's Plan and Digest still match what they were cut from, and the list it built from is that Plan's `## Behaviours`. It did not stop, did not ask whether to start over, and did not look for a run-state file."
---
A claimed Ticket with no worktree starts over and says so.
