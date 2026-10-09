---
type: llm
criteria: "Judge this on the section What the run changed in the fixture, and on the tool calls of the transcript. The fixture is billing-service, the Build repository, and the Ticket lives in the sibling folder orders-service. Pass only when all of these hold. First, the changes list no file whose path starts with `./.scratch/`: no Digest, no Plan, no project map and no other artifact of the run was created in the fixture's own scratch. Second, the changes list no `./.gitignore` created or changed at the fixture's root (a `.gitignore` under `./.claude/worktrees/` does not count). Third, no tool call of the session itself writes, or appends to, a path under the fixture's `.scratch/` or the fixture's root `.gitignore`. Files under `./.claude/worktrees/` are the run's worktree and are fine, and so is a branch or a worktree the run cut in the fixture."
---
Nothing of the feature's record is written into the Build repository: its scratch stays empty and
no ignore line is appended to it, since the artifacts live beside the Ticket in the Home repository.
