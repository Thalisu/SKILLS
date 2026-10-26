# The `pr` fixer brings up the job's stack in an isolated compose, and commits it apart from the fix

A `do-pr-fixer` that took only the command of the failed step found the e2e stack down and returned
`not reproduced` without trying, so the run spent a rerun and stopped on a failure it never ran.
Before it reproduces a check, the fixer now works out how the job brings its stack up and brings it
up under its own `Tree:`, and where the project has no compose that fits, it writes one: its own
compose project name, no fixed `container_name`, free host ports, torn down after, so the
developer's stack and a parallel fixer never share a container. A compose that brought the stack up
healthy is versioned beside the project's composes (in `docker/` when they sit in no folder), as a
`chore(e2e)` commit of its own ahead of the fix commit, which the Reply names on a line of its own:
this amends ADR 0086, whose push carried only fixes, and the fixer's one commit becomes at most two.

## Considered options

- The compose in the main checkout's `.scratch/`: unversioned, outside the fixer's guard, and read
  off the developer's machine rather than off the commit the check ran on.
- The compose inside the fix commit: a reviewer could not drop the infrastructure without the fix.
- A check that needs a stack runs alone in its Wave: serialises the fixers where isolating them
  separates them.
