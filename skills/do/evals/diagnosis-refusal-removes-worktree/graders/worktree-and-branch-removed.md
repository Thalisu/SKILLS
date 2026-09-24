---
type: llm
criteria: "At the end `git worktree list` shows the main checkout alone and `git branch --list 'do/*'` prints nothing: the worktree the run cut for the diagnosis and its branch are both gone, removed by the run itself without a force flag on either. Any instrumentation the run added lived only in that worktree and none of it reached main. The Ticket file in the main checkout still reads `**Status:** ready-for-agent`, its criteria unticked and no evidence appended. The reply says the worktree and its branch were removed, and nowhere asks the developer to remove a worktree, delete a branch or reset the Ticket's status before running `/do` again. main still points at the fixture commit and the README's uncommitted line is intact."
---
A refusal on the diagnosis branch removes the worktree and branch the run cut, so the rerun needs no reset by hand.
