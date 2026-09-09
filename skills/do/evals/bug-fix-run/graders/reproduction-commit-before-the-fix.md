---
type: llm
criteria: "On `main` after the run, `git log` holds two commits on top of the fixture commit, in this order: first a commit that adds a failing reproduction (a test file change only, no change to `src/notes.js`), then a commit that carries the fix to `src/notes.js`. Checking out the reproduction commit and running its test shows it red, and the same test is green at the fix commit. Each commit is a conventional commit whose body carries a `Behaviour:` line and the single-file command that proves it. The reproduction never lands after the fix and the two are never squashed into one."
---
The failing reproduction lands before the fix, so the history tells the story.
