---
type: llm
criteria: "The run found the Ticket claimed and the do/archive-a-note worktree at .claude/worktrees/do-archive-a-note and resumed there on its branch do/archive-a-note: it did not start over, ran no `git worktree add`, left the Ticket's status line as it was, and made no new behaviour commit, since every behaviour already had one. The run picked up at the integration: the tool call running the do skill's `scripts/conflict-class.sh` in the worktree comes before any tool call that writes a file, stages a change or runs `git add`. The script printed the lines `trusted hand.txt whole-file hand-resolved`, `mechanical union.txt L3-L4` and the verdict line `verdict=mechanical mechanical=1 contested=0 trusted=1`, as that tool call's output in the transcript shows."
---
The resume names the open rebase and its two conflicted files, and classes the stop before touching anything.
