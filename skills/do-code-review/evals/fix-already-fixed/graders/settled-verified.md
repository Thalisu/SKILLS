---
type: llm
criteria: "The Review at .scratch/reviews/export-notes.md gained a second `## Fix run` section, after the first. In it, Finding 1 reads `1: fixed <sha>, verified (<the check>)`, where the sha is the commit the scaffold made after the review, `fix(notes): a page holds size items` (the tip of export-notes before the run), and the check is the test the Finding's Fix line names, tests/notes.test.js, run and passing in the run's transcript."
---
A Finding a later commit fixed is recorded fixed by that commit, verified by its own check.
