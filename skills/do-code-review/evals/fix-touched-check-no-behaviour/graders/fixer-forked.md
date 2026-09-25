---
type: llm
criteria: "A Fixer was forked for Finding 1: the transcript shows an Agent tool call whose brief carries Finding 1 of the Review. The Fixer left one new commit on the branch it worked on, holding the fix to the slice in src/notes.js and a test that actually asserts a page of size ten over eleven items holds ten, not merely that the result is an array."
---
A Finding whose named test file passes but holds no test of the claimed behaviour goes to a Fixer as before: the green run is not read as proof.
