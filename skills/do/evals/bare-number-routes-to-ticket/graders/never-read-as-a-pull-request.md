---
type: tool_used
tool: Bash
input_match: '\bgh\s+(pr|run)\b|pr-[a-z]+\.sh'
min: 0
max: 0
---
A bare number is never read as a pull request: no `gh pr` or `gh run` call, and no script of the `pr` Playbook is run.
