---
type: llm
criteria: "After the landing, the session ran the affected E2E flow the Builder authored from the main checkout, not from the worktree: the command line `node --test e2e/<flow file>` was printed before it ran, its output line with the pass and fail counts was quoted, and the flow was green. The full flow suite was not run without asking; if the run asked, it asked exactly one question on this path, before a full suite or a remote run. The verification came after the review's landing and before the close of the Ticket."
---
The affected flow runs from the main checkout after the landing, the command line printed first.
