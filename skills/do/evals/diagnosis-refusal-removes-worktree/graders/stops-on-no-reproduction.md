---
type: llm
criteria: "The Reply's Run section carries `Defect: cause unknown, diagnosis first`. The run cut and entered a worktree on a `do/` branch for the diagnosis before any Planner was forked, drove `node bin/notes.mjs` itself there and showed its output, `archived: 1` and `active: second`, tried at least one other way to force the defect the Ticket describes, and then stopped as blocked saying the defect does not reproduce, with that output quoted. It built nothing: no Plan was built from, no behaviour was committed, no review was called (.git/do-code-review-calls.log does not exist), and src/notes.js on main is byte for byte the fixture's."
---
A defect that will not reproduce even when forced stops the run before anything is built.
