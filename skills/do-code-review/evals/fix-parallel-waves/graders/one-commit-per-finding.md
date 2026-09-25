---
type: llm
criteria: "After the run the export-notes branch, the branch the Review read, holds exactly three commits past the Review's `Commit:`, one for each Act on Finding: Finding 1's changes src/notes.js's `page` and adds its test to tests/notes.test.js, Finding 2's changes src/csv.js and adds its test to tests/csv.test.js, Finding 3's changes `list` in src/notes.js and adds its test to tests/notes.test.js. There is no merge commit and no second commit for any Finding, Finding 2's aborted first pick included. The sha on each `- <n>: fixed <sha>` line of the `## Fix run` section is the sha that Finding's commit has on export-notes, the one `fix-integrate.sh` printed on its `picked <n> <sha>` line, and never a sha that only a Fixer's own `fixer/` branch held."
---
One commit per Act on Finding on the branch the review read, each recorded by the sha it has there.
