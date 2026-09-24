---
type: tool_used
tool: Bash
scope: all
input_match: 'fix-integrate\.sh.*\s1='
min: 0
max: 0
---
Nothing of the Fixer that went silent is brought onto the reviewed branch: its branch is never handed to the integration script, alone or beside another.
