# The Fixers run in Waves, each in its own worktree, on a floor a script computes

`do-code-review` forked one Fixer per `Act on` Finding one at a time because they all wrote in the
one tree, with
[separate-before-serializing-shared-state](../../.agents/principles/separate-before-serializing-shared-state.md)
cited for the serialization. Each Fixer now gets a worktree and a branch of its own, and the
Findings whose files are disjoint run at once, in **Waves** a script reads off the Review, which the
review may cut finer with one reason per cut and which nothing may widen. That eliminates the shared
write target the principle says to eliminate before serializing anything, at the price of an
integration step and of the Fixer's own commit sha never reaching the record, since the sha the
record keeps is the one on the branch the review read.

## Considered options

- Parallel Fixers in the one tree, paired by disjoint files: the git index stays a shared write
  target, and the turn to commit would be a line in the Fixer's brief, which the same principle
  rules out as concurrency control.
- Every Finding at once with no Wave rule, conflicts caught at the integration: two Fixers in one
  function both commit and both report fixed while the merge keeps one, so the Review claims two
  fixes and one of them is gone.
- The Waves as the orchestrator's own reading of the Findings: a coupling judgment whose error runs
  in the widening direction, which is the one direction where a mistake costs a fix lost in silence.

## Consequences

- [.agents/research/do.md](../../.agents/research/do.md) left this shape out of `do`'s build loop,
  on serialized shared-asset creation and on a field report of two parallel sessions corrupting one
  tree. The second reason does not reach Fixers with a worktree each; the first one does, so the
  project's duplication scan runs after the last Wave and a dirty result goes to the Gate fixer.
- The containment of a Fixer that never returns loses its cascade: the run stopped forking because
  that Fixer might still be writing in the shared tree, and it now writes only in its own, so the
  rest of the Wave and the Waves after it go on, its worktree and branch are left in place and
  named, and its Finding alone reads `not fixed`.
