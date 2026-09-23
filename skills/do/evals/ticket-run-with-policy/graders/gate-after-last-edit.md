---
type: llm
criteria: "The gate is the session's own and ran in the worktree after the Builder's last edit and after the session read the diff: it showed the command lines and ran the full unit suite (`node --test 'src/**/*.test.ts'`) and the typecheck (`tsc --noEmit`), quoting the relevant output line of each (the pass and fail counts; no errors). Lint and format, which the fixture does not have, read `skip: <reason>` with the reason stated. A gate result the Builder produced inside its own window was not reused as the evidence, no gate result produced before the last edit was reused either, and the gate ran before the review was called."
---
The gate is the session's, produced after the last edit, and the relevant lines are quoted.
