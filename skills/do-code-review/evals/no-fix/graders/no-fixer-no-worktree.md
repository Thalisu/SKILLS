---
type: llm
criteria: "The Review was written to .scratch/reviews/export-notes.md and the run stopped there. No Fixer or Gate fixer was forked, neither `do-code-review-fixer` nor `do-code-review-gate-fixer` by name nor a general-purpose sub-agent in their place, no worktree was created (`git worktree list` shows one entry), no commit was made, and the export-notes branch is where the scaffold left it. The Review carries no `## Fix run` section."
---
--no-fix writes the Review and stops.
