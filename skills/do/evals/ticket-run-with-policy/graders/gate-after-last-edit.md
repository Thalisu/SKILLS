---
type: llm
criteria: "After the last edit, in the worktree, the run showed the command lines and ran the full unit suite (`node --test 'src/**/*.test.ts'`) and the typecheck (`tsc --noEmit`), quoting the relevant output line of each (the pass and fail counts; no errors). Lint and format, which the fixture does not have, read `skip: <reason>` with the reason stated. A gate result produced before the last edit was not reused as the evidence, and the gate ran before the review was called."
---
The gate output is produced after the last edit and the relevant lines are quoted.
