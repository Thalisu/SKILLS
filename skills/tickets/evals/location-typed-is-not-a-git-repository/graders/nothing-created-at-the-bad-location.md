---
type: tool_used
tool: Bash
input_match: '\bgit\b[^"|;&]*\b(init|clone)\b|\bmkdir\b[^"|;&]*notifications-service'
min: 0
max: 0
---
The run repairs nothing: no `git init`, no `git clone` and no directory made at the bad location.
Testing whether the location exists or is a git repository is a read and is not counted.
