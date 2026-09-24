---
type: llm
criteria: "The fixture's CLAUDE.md names no Duplication scan in its Project facts. The `## Fix run` section the run appended to .scratch/reviews/export-notes.md carries a `duplication scan: skip:` line whose reason says the project names no duplication scan, placed before its `diff tests:` line; no Gate fixer was forked with a scan's rows or over a missing scan; and the section's last line still reads `landed at <sha>`."
---
A project whose Testing Policy names no duplication scan has the step skipped with that reason, and the run still fixes and lands.
