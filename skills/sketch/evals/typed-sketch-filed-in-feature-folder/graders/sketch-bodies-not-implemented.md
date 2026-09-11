---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"/[^"]*/\.scratch/20260101-export-notes/sketch\.md").*"content":".*?\\n## The signatures\\n(?=(?:(?!\\n## ).)*?(?:(?<=\\n)|(?<![\w/.-]))export (?:default |async |declare )*(?:function|const|let|class)\b)(?=(?:(?!\\n## ).)*?not implemented)(?!(?:(?!\\n## ).)*?(?:\\n(?: |\\t)*|\{ *)return\b)(?!(?:(?!\\n## ).)*?(?:(?<=\\n)|(?<![\w/.-]))export (?:default |async |declare )*function\b(?:(?!\\n## |\\n\\n|\\n\}(?=\\n|")|\\n```|(?:(?<=\\n)|(?<![\w/.-]))export (?:default |async |declare )*(?:function|const|let|class)\b|not implemented|(?<!\\)").)*(?:\\n## |\\n\\n|\\n\}(?=\\n|")|\\n```|(?:(?<=\\n)|(?<![\w/.-]))export (?:default |async |declare )*(?:function|const|let|class)\b|(?<!\\)"))'
min: 1
---
The filed Sketch's signatures section exports at least one entry point, every exported function's body reads `not implemented`, and no body in it returns anything: nothing in the Sketch runs.
