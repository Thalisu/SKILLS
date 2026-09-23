---
type: llm
criteria: "After the Builder returned and before the gate, the session read the diff on the branch itself in the worktree (`git diff` against the commit the worktree was created from, or `git log -p` or `git show` over the branch's commits) and wrote its own summary of it in the Reply's Run section, in its own words and never the fork's lines passed through. The order in the transcript is the fork's return, the session's own diff read, the gate, then the review: the review was never called before the gate, and the gate was never run on a tree the session had not read."
---
The session reads the Builder's diff and gates the tree before anything reaches the reviewers.
