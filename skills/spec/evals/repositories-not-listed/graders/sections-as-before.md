---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/\.scratch/[^"]*/spec\.md").*"content":"# (?:(?!\\n).)+(?:\\n)+Journey: (?:(?!\\n).)+\\nStatus: ready-for-agent(?:\\n)+## Problem Statement *\\n.*?\\n## Solution *\\n(?:(?!\\n## ).)*?\\n## User Stories *\\n.*?\\n## Implementation Decisions *\\n.*?\\n## Testing Decisions *\\n.*?\\n## Out of Scope *\\n.*?\\n## Further Notes *(?:\\n|")'
min: 1
---
The Spec of a one-repository plan is the Spec as it was before the repositories section existed:
the title, the `Journey:` line, the `Status:` line, then the seven sections in their order, with
User Stories directly after Solution and no section between the two. Read on the whole content of
the call that wrote the Spec, since the later sections sit past what the judge is shown of it.
