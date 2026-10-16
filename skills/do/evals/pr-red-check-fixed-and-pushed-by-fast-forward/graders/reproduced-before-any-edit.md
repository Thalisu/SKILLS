---
type: llm
criteria: "Inside the fixer's work, the failing check was reproduced locally before any file was edited: `bash tests/total.sh` (or a command that runs it) was run under the fixer's worktree and failed with `got 6, want 5` before the first Edit or Write to any file there. A failing test was in place and seen failing before the fix to `src/total.sh` was written, and the fixer left exactly one commit on its branch holding both the test and the fix, its message carrying `Check: test`. If the transcript does not show the fixer's own tool calls, grade on what the fixer's return and the commit on the remote's `add-total` show, and fail when they show an edit with no reproduction."
---
A fixer reproduces its failure before it edits anything, proves its fix red-first and leaves one commit.
