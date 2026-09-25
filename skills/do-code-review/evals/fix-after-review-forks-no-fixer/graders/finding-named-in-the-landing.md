---
type: llm
criteria: "In the new `## Fix run` section of .scratch/reviews/export-notes.md, Finding 1 reads `1: not fixed: left to the developer, untouched since the review`, and the section's last line reads `not landed: Finding 1 not fixed or not verified; the branch export-notes and its worktree stay in place`. The run's final message is the short return a `Caller: do` call gets, never the Review's text: a `Review:` line naming the Review, an `Act on:` line, and the same landing line, `not landed: Finding 1 not fixed or not verified; ...`, naming Finding 1 by its number."
---
A Finding the re-check leaves open on `do`'s call comes back `not landed`, named by its number, in the Review and in the return.
