---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/\.scratch/[^"]*/spec\.md")(?!.*\\n#+ *(?i:Repositor(?:y|ies))\b)(?!.*\\n- (?:(?!\\n).)*\(Home repository\):)'
min: 1
---
A plan that names no repository besides the one the session is in gets a Spec with no repositories
section and no line in the shape `- <name> (Home repository): <path>` anywhere in it. The runner
has no grader that reads a pattern as absent from a file, and the judge is shown only the head of
the call that wrote the Spec, so this reads the whole content of that call: it passes only when the
Spec was written by a call whose content carries neither.
