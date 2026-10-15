---
type: llm
criteria: "The run went on as a first run of the Ticket does and ended on a ticket run's Reply. Pass only when all of these hold. First, the run claimed Ticket 02, cut one worktree for it under .claude/worktrees/ on a do/ branch, and forked the do-builder agent, which committed each of the two behaviours with a `Behaviour:` line in the commit's body. Second, the run went past the build to the Gate and the review, and its final message is the five-part Reply of a ticket run (the `Playbook:` and `Plan:` lines, `## For whom`, `## Pending debt`, `## Next step`), with no `## Run` section. Third, the final message does not say the run resumed or started over, since no earlier run claimed the Ticket or left a worktree, and it is not a refusal at the door, a stop at the Plan, or a question to the developer."
---
A Ticket stopped at the Plan had nothing but a Plan, so once its blocker is resolved the same
command runs it as a first run, to the Reply any ticket run ends on.
