---
type: llm
criteria: "`git worktree list` at the end shows one worktree on do/archive-a-note, at the path the fixture created, and no other worktree: the run entered the existing one and created none. The branch holds the fixture's two commits followed by at least one new commit whose body carries the third behaviour (Archive picked twice on the same note is a no-op) with a test change and an implementation change under src/; no new commit carries the first or the second behaviour again. The main checkout's dirty README.md is untouched and the Ticket still reads claimed. The evidence is git output the run produced, not the run's own claim."
---
No second worktree, and the loop continued at the third behaviour.
