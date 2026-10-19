---
type: llm
criteria: "Read .fake/gh.log and the project tree. The log holds no `pr checks` call and no `run view` call, no `do-pr-fixer` was forked, no worktree or branch was created, nothing was pushed, and no file was created or edited in the project: a fork's pull request is stopped before any watch, worktree or fork."
---
A fork's pull request stops at the read-back: no watch, no log read, no worktree, no fixer, no push, no file written.
