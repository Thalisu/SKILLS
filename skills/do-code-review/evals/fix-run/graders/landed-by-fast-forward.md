---
type: llm
criteria: "The export-notes branch was fast-forwarded onto the branch the Fixer committed on, `git merge --ff-only`, and no merge commit and no rebase was needed. After the run `git worktree list` shows no fix/ worktree and `git branch` shows no fix/ branch: the run removed what it created."
---
The landing is a fast-forward and the fix worktree is gone.
