---
type: llm
criteria: "Pass only when all of these hold. First, the section `Worktrees after the run` lists a worktree under .claude/worktrees/ beside the main checkout, and `Branches after the run` lists the branch do/archive-a-note: the run removed neither. Second, `Commits the run made` shows the commit the do-builder agent made on that branch, the one whose body carries a `Behaviour:` line, and the run never reset, reverted or dropped it. Third, the run never landed that branch anywhere: no merge or rebase onto main or onto a spec/ branch in the transcript. Fourth, nothing was created or changed in the sibling repository notes-web: no tool call in the transcript writes there, by the session or by any agent it forked."
---
The stop keeps what the build already made: the worktree, its branch and the commit on it.
