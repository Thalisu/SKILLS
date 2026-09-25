---
type: llm
criteria: "Finding 1's Fixer committed and its test passes; that fix turns `npm test` red on `the preview shows the first ten active notes`. The transcript shows exactly one Agent tool call forking `do-code-review-gate-fixer` (or a `general-purpose` fork carrying that agent's definition) with that red block, never a second one: the fixture's stand-in ends its turn without writing the return file the brief names, so the run reads it missing after the third `returns.sh` window and stops there instead of retrying. `.scratch/reviews/export-notes.md`'s new `## Fix run` section reads `- gate fixer: no return`."
---
A Gate fixer whose return file never lands ends the attempts at one: it may still be writing in
the tree, so the run does not fork it again.
