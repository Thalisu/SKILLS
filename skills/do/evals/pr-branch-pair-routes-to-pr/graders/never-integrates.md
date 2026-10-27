---
type: tool_used
tool: Bash
input_match: '\bgit\b[^"]*\b(rebase|merge(?!-)|cherry-pick|push)\b'
min: 0
max: 0
---
The pair is never integrated by the run itself: no `git rebase`, `git merge`, `git cherry-pick` or `git push`.
