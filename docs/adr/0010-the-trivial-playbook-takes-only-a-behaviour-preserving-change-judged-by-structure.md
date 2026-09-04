# The trivial playbook takes only a behaviour-preserving change, judged by structure

The `trivial` playbook of `do` accepts a change no test could tell before from after, so the
existing suite is its whole gate: a typo, a doc or a comment, formatting, the wording of a log, a
rename inside one file, dead code, a lint fix. It runs in place on the current branch, dispatches
no test author, and lands as one commit after typecheck and the suite that already covers the
touched files. Size is never the test, for the reason ADR 0001 gives: a bug, however small,
changes behaviour and goes to `bug-fix` red-first under the Testing Policy; a new exported symbol
or a changed signature crosses a boundary and goes to the chain or to `architect`; a
user-observable effect goes to the chain. A condition that fails mid-run stops the playbook before
any commit and names the playbook the request re-routes to.

## Considered options

- "Small enough for one commit" as the door: the same in-the-moment judgment ADRs 0001 and 0003
  removed, and the bypass of the chain ADR 0008 forbids.
- A one-line bug fix as trivial: the policy's `bugfix` origin needs the red run first, and a fix
  with no reproduction is the hypothesis poteto's bug-fix playbook refuses to ship.
