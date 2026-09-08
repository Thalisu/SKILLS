---
type: llm
criteria: "A git worktree under .claude/worktrees/ on a branch named do/archive-a-note was created with `git worktree add` from the current HEAD before the first edit to any file under src/, and every edit and commit of the build happened in that worktree. The main checkout's uncommitted change to README.md was never staged, committed, reverted or edited: at the end, git status in the main checkout still shows README.md modified with the scaffold's extra line. The worktree folder was excluded through .git/info/exclude and .gitignore was not edited."
---
The worktree exists before the first edit and the main checkout's dirty file is untouched.
