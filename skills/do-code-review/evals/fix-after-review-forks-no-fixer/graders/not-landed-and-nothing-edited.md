---
type: llm
criteria: "The run held Finding 1 to the branch before anything else (it ran scripts/unsettled.sh, or otherwise found that no commit since the Review's Commit: touched src/notes.js), appended one new `## Fix run` section to .scratch/reviews/export-notes.md after the first, and kept the first section and every section before it word for word. In the new section Finding 1 reads `not fixed`, never `fixed` or `stale`, and its last line reads `not landed`. Nothing landed: main still points at the fixture commit, and nothing was pushed. The only file the run wrote is the Review; src/notes.js and tests/notes.test.js are unchanged."
---
A Finding the branch never fixed stays open on `do`'s call, and the call lands nothing.
