---
type: llm
criteria: "The `## Fix run` section the run appended to .scratch/reviews/export-notes.md carries, after its `wave 1:` line and right before its `diff tests:` line, a line reading `duplication scan: <the scan command>: dirty: makeNotes`, naming `makeNotes` and not `seedArchive`, and its `gate fixer:` line names a commit rather than `not needed`."
---
The record keeps the scan's dirty result beside the Diff tests line, and the Gate fixer line shows the block reached it.
