# A conflict between two Fixers is aborted and re-routed, never resolved

The integration of a Wave cherry-picks each Fixer's commit onto the branch the review read, in
Finding order, and a conflict is aborted: the Finding moves to the next Wave and its Fixer is
dispatched again over the branch as it now stands, twice at most before it reads
`not fixed: conflicted with Finding <m>`. The conflict machinery the landing already owns
([ADR 0028](0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md),
[ADR 0034](0034-a-contested-hunk-takes-the-target-side-and-what-it-sets-aside-is-reapplied-after-the-integration.md))
is deliberately not reached here, because a conflict between two Fixers of one Review is not a
target that moved: it is the Wave floor having missed a coupling, or a Fixer having touched what its
Finding did not name, and resolving it hides that bug and lets the Review report both Findings fixed
while the merge kept one. `fix-integrate.sh` therefore sequences and recovers and judges nothing: it
runs `git cherry-pick`, reads the exit code, runs `git cherry-pick --abort`, and prints one line per
Finding.

## Considered options

- The mechanical and contested classes with the Loss ledger and the `ledger-judge`, as the landing
  runs them: the record would claim two fixes where one survived, and the review's fix path would
  carry a sub-protocol for a case its own Wave rule exists to prevent.
- The Finding left `not fixed` with no re-route: it pushes onto a second human `fix` call a case the
  run can settle, since the conflict names the two Findings and the serial order that fixes it.
- A strong sub-agent re-routing after the conflict: the conflict is exact evidence with one possible
  answer, later Wave for the loser, so there is nothing for a model to weigh and the fork buys
  latency for a conclusion the script already holds.
