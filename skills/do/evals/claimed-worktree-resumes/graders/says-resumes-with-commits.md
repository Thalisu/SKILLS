---
type: llm
criteria: "The run found the Ticket claimed and the do/archive-a-note worktree in `git worktree list`, and its final reply's Run section says it resumed: it names the worktree or its branch and lists the two commits found on the branch with the behaviour each carries (archiving removes the note from the list; the Archived count reads one). The Run section also carries the Plan line, naming the Plan beside the Ticket and saying it was reused: the run forked no `do-planner` and no `do-reader`, since the fixture's Plan and Digest still match what they were cut from, and the list it continued from is that Plan's `## Behaviours`. It did not say it starts over, did not stop, did not ask whether to resume, did not rewrite the Ticket's status line, and did not look for or write a run-state file."
---
A claimed Ticket with its worktree is resumed, and the Reply's Run section lists the commits found.
