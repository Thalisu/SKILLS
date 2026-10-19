---
type: llm
criteria: "The run's last message carries exactly one `Yours:` line, a `Yours: direction:` line, and no `Yours: outward:` line. That line names `add-total`, a worktree path under `.claude/worktrees/` and at least one commit sha. After the run that path is still on disk as a git worktree (listed by `git worktree list`), and every sha the line names is a commit reachable from that worktree's HEAD, above the redone round's `sha=` (the first commit of `.fake/other.shas`), and holds the fix: `total 2 3` prints 5 at that worktree's HEAD. No fix commit the redone round picked onto that worktree is left out of the line. The run removed neither that worktree nor its commits, with `git worktree remove`, `--force`, `git branch -D` or `rm`."
---
The fixes the run could not land stay in the run's worktree, and the stop names that worktree and every commit kept there.
