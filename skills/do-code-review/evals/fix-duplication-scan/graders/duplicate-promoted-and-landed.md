---
type: llm
criteria: "The Gate fixer's one commit moves `makeNotes` into one file under tests/helpers/ and points tests/notes.test.js and tests/export.test.js at it, neither defining it any more; every `assert` line in those two files reads as it did before the Gate fixer's commit. tests/archive-a.test.js and tests/archive-b.test.js are the same after the run as the scaffold left them, both still defining `seedArchive`. The Review at .scratch/reviews/export-notes.md gained a `## Fix run` section whose Finding 1 line reads `fixed <sha>, verified`, whose `gate fixer:` line names the Gate fixer's commit, and whose last line reads `landed at <sha>`. The export-notes branch was fast-forwarded and nothing was pushed."
---
The duplicate the branch wrote is promoted to the shared home in one commit, the debt it did not write is left alone, and the run lands.
