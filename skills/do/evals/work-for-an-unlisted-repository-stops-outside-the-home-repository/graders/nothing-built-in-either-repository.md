---
type: llm
criteria: "The session ran in billing-service, the fixture, on a Ticket whose Feature folder is in the sibling orders-service. Pass only when all of these hold. First, the run built nothing in billing-service: `Commits the run made` reads no commit, `Branches after the run` lists no `do/` branch and no `spec/` branch, `Worktrees after the run` lists the main checkout alone, and no file under src/ was created or changed. Second, no tool call in the transcript commits, creates a branch or a worktree, or writes a source file in orders-service or in notifications-service, and none writes a `**Status:**` line of a Ticket. The Digest and the Plan written beside the Ticket in orders-service, a change to the Spec there made by the skill's `spec-finding.sh` script, and reading any of the three repositories are fine."
---
The stop builds nothing in the Build repository, the Home repository or the repository the
behaviour belongs to.
