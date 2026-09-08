---
type: llm
criteria: "The run built the Ticket to the gate: the worktree branch do/archive-a-note holds one commit per behaviour, and after the last edit the run ran `node --test` and `tsc --noEmit` in the worktree, quoting the pass and fail counts. Only then did the review step read `skip: do-code-review not listed`; the run called no review skill, did not try to land, and the verification and close steps read `skip: nothing landed`."
---
The gate completes before the review is skipped, and nothing after it runs.
