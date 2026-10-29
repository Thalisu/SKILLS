# A test author gets one fix attempt and hands back what it ruled out

A dispatched test author whose run does not reach the target it was dispatched for, red for the
declared reason for a unit test and green for a flow, gets exactly one **Fix attempt** on its own
test and then stops, returning the verdict `HANDBACK`: the last run's output, the hypothesis it
tested and what that ruled out, its reuse audit's verdicts and the files it changed. The bound is
attempts and never a token budget, because a forked agent cannot read its own consumption: inside
a fork `CLAUDE_CODE_SESSION_ID` resolves to the parent session's transcript and no transcript
carries `isSidechain` lines, so `skills/do/scripts/context-usage.sh` measures the orchestrator and
nothing else. The **Builder** routes on the diagnosis the **Handback** carries, not on the verdict:
a diagnosis naming production (a bug, a missing seam, an unreachable state) gets no second author,
since no test author may touch production code, and a diagnosis naming the test gets at most one
re-dispatch with the **Handback** as input.

## Considered options

- **A token budget the author reads for itself**: rejected on the measurement above, not on taste.
- **A whole-dispatch budget instead of a bound on the diagnostic loop**: rejected as a guard on the
  symptom. The cause is a mandate with no exit, `It MUST be green` in the E2E core and `fix and
  rerun` in the unit core, and a ceiling on the loop is what removes it.
- **Handing back only the changeset**: rejected because the files are already on disk in the
  worktree. What dies at the window boundary is the diagnosis, and without it the next author
  re-pays the mandatory reuse audit and tests the hypothesis the first one already ruled out, which
  splits the cost across two bills instead of removing it.
- **Reusing `BLOCKED` for the unit author and `RED` for the flow author**: rejected as two names for
  one concept, and because `BLOCKED` already means the opposite, that the author needs the caller to
  act before it can proceed at all.

## Consequences

An unbounded chain of authors is the original cost redistributed, so the ceiling is one
re-dispatch per behaviour: a second author that still misses the target stops the run and reaches
the developer, because the second window is itself the evidence that the fault is not in the test.

Amended: per ADR 0113, the reasons `build-loop.md`, `flows.md` and `global-authors.md` gave beside
the build loop's rules live here. The caller counts the runs an author's `Run` section names, since
a forked author's report reaches no hook and the count is the caller's or nobody's. A re-dispatched
author re-checks each path the carried reuse audit names, since the tree may have moved between the
two dispatches, and the carried sections go between `<handback id>` tags, since a failing test's
output can carry a line from a fixture, seeded data or a dependency's error that reads like an
order. A missing seam is built in production code and never mocked around, since the mock would pin
the implementation the seam exists to hide. One author is in flight at a time and never a batch of
tests ahead of the code, since a test written before the code it depends on describes a tree that
does not exist yet and two authors in flight each create the shared asset the other cannot see;
while it runs the author is the only writer in the tree, since its changeset is its diff against the
baseline it took. The expected red is read off the tree at each cycle, since the behaviours
committed before it have already changed what fails. Every author dispatch runs with
`run_in_background: false`, since the loop's next step waits on the verdict and an author left in
the background comes back as a launch with no verdict to read. A global author's `BLOCKED` on a
missing Project map slot gets no second dispatch, since the map does not change during the run and a
second dispatch would meet the same `BLOCKED`, and each global author reads its commands from the
map file, so no dispatch derives the map again. A file is opened only when the loop is about to edit
it, which leaves the window to the behaviours still ahead. A green is never a constant or a branch
that recognizes the test's own inputs, since that is the test rewritten as code and the review reads
it as a defect, and a change to an assertion goes back to its author stated as the contract, since a
test bent to fit the code stops proving the behaviour. Each behaviour is committed before the next
one begins, with its promotion changeset and staged by path, since a commit carrying two behaviours,
or a behaviour left half-built, is a checkpoint the resume cannot trust, a promotion split from its
test leaves the other test file broken at that commit, and staging by path keeps out what the
behaviour did not write.
