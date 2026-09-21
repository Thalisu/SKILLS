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
