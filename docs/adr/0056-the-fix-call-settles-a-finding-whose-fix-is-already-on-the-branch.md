# The fix call settles a Finding whose fix is already on the branch

A Finding could stay unsettled after its fix landed: a Fixer that never returned leaves `not fixed`
beside a commit that exists, and a Fixer sent to a Finding already fixed reports `stale`, which
never settles. `do` then stopped as blocked before its fix call and told the developer to edit the
Review by hand, an action the run could take. The fix call now re-runs the check of every Finding
whose latest line is not `fixed` before it forks a Fixer, and when the check passes and a commit
since the Review touched the Finding's location, it appends `- <n>: fixed <sha>, verified (<check>)`
in a new `## Fix run` section and forks no Fixer for it. `do` makes the fix call on such a Review
instead of stopping, since no Fixer's commit reaches the Gate fixer on that path.

## Considered options

- The `do` session deletes or marks the Findings itself: it would open a file `do-code-review` owns
  (ADR 0005), pull the Findings into the session's window, and deleting erases the record that the
  Findings existed.
- Keep the stop and hand the edit to the developer: an action the run can take, handed over, against
  [never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md).
