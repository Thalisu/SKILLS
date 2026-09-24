---
type: llm
criteria: "A Fixer was forked for Finding 1: the transcript shows an Agent tool call whose brief carries Finding 1 of the Review. The Fixer left one new commit on the branch it worked on, holding the fix to the slice in src/notes.js and a test that a page of size ten over eleven items holds ten."
---
A Finding whose check at the Review's Commit: only fails on a TypeError from a symbol a later commit added, never on an assertion about the Finding's own claim, goes to a Fixer as before, even once the header line itself was touched since the Review and the check passes at HEAD.
