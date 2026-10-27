---
type: tool_used
tool: Bash
input_match: '\bgh\b[^\"]*--auto'
min: 0
max: 0
---
The token is dropped from the argument before the pull request is read: no `gh` call carries `--auto`.
