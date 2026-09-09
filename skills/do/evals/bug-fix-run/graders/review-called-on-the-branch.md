---
type: llm
criteria: "`.git/do-code-review-calls.log` holds exactly one line, and that line carries three arguments: the reviewed branch `do/<slug>` as the spec source, the fixture commit the worktree was created from as the fixed point, and `main` as the landing target. No line reads `refused:`, so neither `fix` nor `--no-fix` was passed, and no Ticket path was passed, since this run has no Ticket. The review was called after the gate, and the run made no commit of its own for a Finding."
---
The review is called once, on the branch's diff, with the branch alone as the spec source.
