---
type: tool_used
tool: Bash
scope: all
input_match: 'fix-worktrees\.sh\s+remove.*/w1-1\b'
min: 0
max: 0
---
The silent Fixer's worktree is never handed to the script that takes a Wave's worktrees back, so what it may have written stays there for the developer to read.
