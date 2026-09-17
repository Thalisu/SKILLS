---
type: llm
criteria: "After the rebase finished, and before do-code-review was called, the gate's command lines ran a second time in the worktree: the full unit suite (`node --test 'src/**/*.test.ts'`) and the typecheck (`tsc --noEmit`), each command line and its relevant output line (the pass and fail counts; no errors) quoted in the reply's Evidence. That output was produced after the rebase; the green gate from before the rebase is not reused as the evidence. The Skill tool call to do-code-review comes after the tool calls of that second gate, never before the rebase, and the fixture's stand-in logged exactly one call in .git/do-code-review-calls.log."
---
The gate's command lines run again after the rebase, and the review is called after them.
