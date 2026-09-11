---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"(/[^"]*/\.scratch/20260101-export-notes/sketch\.md)").*"content":"# (?:(?!\\n).)+(?:\\n)+Shapes: (?:(?!\\n).)+\\nMap: (?:(?!\\n).)+\\nDigest: (?:(?!\\n).)+\\nWritten: \1\\n'
min: 1
---
The filed Sketch opens with its title and the four header keys, one per line and in order, its `Written:` line holding the very absolute path the Sketch is filed at.
