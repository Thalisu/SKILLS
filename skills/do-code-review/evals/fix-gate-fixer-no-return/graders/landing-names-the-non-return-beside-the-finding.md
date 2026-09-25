---
type: llm
criteria: "In .scratch/reviews/export-notes.md's new `## Fix run` section, Finding 1 reads `fixed <sha>, verified (...)` and Finding 2 reads `not fixed` with the reason its test could never turn green (its Claim asks one status field to read two values at once). The section's last line, and the run's final reply, both name the Gate fixer's non-return and Finding 2 together, the non-return first: `not landed: gate fixer did not return, <the failing check>; Finding 2 not fixed or not verified; the branch export-notes and its worktree stay in place`. Neither line reads `not landed: Finding 2 not fixed or not verified; ...` alone, which would drop the live hazard that the Gate fixer may still be writing in the tree. The `fix/` worktree and branch the Gate fixer worked in stay in place, and nothing lands."
---
A Finding left open never gets ahead of the Gate fixer that did not return: that reason warns a
fork may still be writing in the reviewed tree, so the landing line names it beside the Finding instead of
hiding it, per fix.md's `## The landing` and review-format.md.
