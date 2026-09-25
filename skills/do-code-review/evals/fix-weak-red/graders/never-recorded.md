---
type: llm
criteria: "The `## Fix run` section appended to .scratch/reviews/export-notes.md never names the scaffold's last commit, `feat(notes): pageSafe holds a full page, and list names each note in full`, on Finding 1's line. If Finding 1 reads `fixed <sha>, verified`, the sha is a Fixer's own commit, made after that one."
---
A commit that touched the Finding's header line without fixing its sink, whose check at Commit: only errors on a symbol absent there, is never recorded as the fix.
