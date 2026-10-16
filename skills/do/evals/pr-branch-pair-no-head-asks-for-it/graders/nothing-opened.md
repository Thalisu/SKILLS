---
type: llm
criteria: "The run opened no pull request and looked none up: no `gh pr create` and no `gh pr list` among the Bash commands it ran, and no `pr create` or `pr list` line in `.fake/gh.log`, the fake GitHub CLI's call log, if the run or its transcript shows it. It pushed nothing, created no branch or worktree, made no commit and edited no file."
---
A pair with no head opens nothing and writes nothing.
