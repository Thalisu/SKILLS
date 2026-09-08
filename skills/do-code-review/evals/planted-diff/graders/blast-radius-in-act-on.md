---
type: llm
criteria: "The Review holds a Blast radius Finding under ## Act on with Rung: 4 or above whose location is src/report.js, marked outside the diff, saying summary() breaks on the new page signature (the notes passed first, so the call throws items.slice is not a function or returns the wrong count). The transcript shows a proof script in a temporary directory outside the repository that imported src/report.js and called summary(). The Review's Safe because line is present with a Rung."
---
The caller outside the diff is a Blast radius Finding in Act on, proven by a script that called it.
