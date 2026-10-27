---
type: llm
criteria: "Judge this on the transcript's tool calls, since the stand-in's log under `.git` is not in the fixture's changes. The run calls the review once: one Skill call of `do-code-review`, and one `review.sh` call under it, whose arguments carry, in this order, the reviewed branch `do/<slug>` as the spec source, the fixture commit the worktree was created from as the fixed point, `main` as the landing target, the Gate's `command=` line as the gate printed it, then a `Review token:` line with a value. No tool result shows the stand-in printing `refused the argument`, so neither `fix` nor `--no-fix` was passed, and no Ticket path was passed, since this run has no Ticket. The review was called after the gate, and the run made no commit of its own for a Finding."
---
The review is called once, on the branch's diff, with the branch alone as the spec source, the Gate and the review token.
