---
type: llm
criteria: "The Review at .scratch/reviews/export-notes.md gained a `## Fix run` section whose line for Finding 1 reads `not fixed: the Fixer did not return`, and whose line for Finding 2, fixed in the same Wave, reads `fixed <sha>, verified` with the check that proved it. The branch the fix committed on holds a commit for Finding 2 that joins the export's rows with a newline, and none that changes `page` in src/notes.js."
---
A Fixer that never returns costs its own Finding, and the Fixer beside it in its Wave is still read, integrated and recorded.
