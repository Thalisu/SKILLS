---
type: llm
criteria: "After the first landing, the run ran the affected flow from the main checkout with its command line printed (`node --test e2e/...`) and the flow was red, since the CLI exits non-zero after the Fixer's planted commit. The run then fixed it in the worktree as one more unit of the loop: one dispatch to the test author (or the inline test-author skill) with origin `bugfix`, the red confirmed, the smallest fix in bin/notes.mjs so the CLI exits non-zero only after an unknown command, the gate run again in the worktree, and one commit for it on do/archive-a-note after the Fixer's commit. The run never edited files in the main checkout to fix it."
---
A red affected flow is fixed in the worktree as one more unit and gated again.
