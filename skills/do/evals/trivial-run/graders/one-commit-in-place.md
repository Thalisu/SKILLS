---
type: llm
criteria: "After the run, the main branch has exactly one commit on top of the fixture commit; that commit changes only src/notes.js (the helper renamed to nextIdentifier in both its definition and its one call) and no other file; its title is a conventional commit whose type is docs, style, refactor or chore, never feat or fix. The run created no git worktree and no branch, and pushed nothing. The staging used the file's path (git add with the path, or git commit --only with the path), never -A or a bare dot."
---
One commit in place, staging only the touched file, with no worktree and nothing pushed.
