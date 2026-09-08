---
type: llm
criteria: "The run found the Ticket claimed and the do/archive-a-note worktree in `git worktree list`, and its first message said it resumes: it named the worktree or its branch and listed the two commits found on the branch with the behaviour each carries (archiving removes the note from the list; the Archived count reads one). It did not say it starts over, did not stop, did not ask whether to resume, did not rewrite the Ticket's status line, and did not look for or write a run-state file."
---
A claimed Ticket with its worktree is resumed, and the first message lists the commits found.
