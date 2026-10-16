---
type: llm
criteria: "The run pushed nothing and opened no pull request: no `git push` among the Bash commands it ran, and `dev` still absent from the fixture remote `.fake/remote.git` (no `refs/heads/dev` there) if the run or its transcript shows it; no `gh pr create` and no `gh pr list` among its Bash commands, and no `pr create` or `pr list` line in `.fake/gh.log`, the fake GitHub CLI's call log, if the run or its transcript shows it. It created no branch or worktree, made no commit and edited no file."
---
A head the remote does not have is never published by the run, and nothing is looked up or opened for it.
