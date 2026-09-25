---
type: llm
criteria: "The run's final message is a blocked Reply that quotes the fix call's reason, `not landed: Finding 2 not fixed or not verified`, and carries exactly one `Yours:` line, whose class is `direction` and no other word (not `destroy`, `trust` or `outward`). Its choice names Finding 2 and offers both ways out, in these terms or equivalent ones naming both: fix it in the worktree .claude/worktrees/do-archive-a-note (or on the branch do/archive-a-note) and run `/do` on the Ticket again, or overrule it by editing the Review (01-archive-a-note.review.md, its path named on that line or right beside it) and running `/do` on the Ticket again. The run took neither way itself."
---
A Finding the fix call leaves open stops the run under `direction`, offering to fix it or to overrule it in the Review and call `fix`.
