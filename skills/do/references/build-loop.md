# The build loop

The loop a Playbook that builds in a worktree runs once its behaviours list exists: one behaviour,
one dispatch, one green commit, repeat. It is read by the step that is about to build, in `ticket`,
`bug-fix` and `refactoring`, by the E2E flows step for the test authors it names, and by the resume
step for the `Behaviour:` line the loop's commits carry. The rest of what those Playbooks share is
in [mechanics.md](mechanics.md).

## The build loop

One behaviour at a time, from the list the Playbook wrote, in its order. Each behaviour is one
verifiable unit that ends in one green commit, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md).
Each file is read at the moment the loop edits it, never ahead of the behaviour that edits it, and
named on that behaviour's build line for the Reply's Run section, per [reply.md](reply.md), so that
the only source the loop brings into the session is source the run changed.

1. Dispatch the unit test author (the test authors, below) with the complete dispatch input: the
   behaviour to prove, who relies on it and what a wrong or missing result costs them, the target,
   the origin (`new feature`, or `bugfix` when the line reproduces a defect), the expected red, and
   placement when it matters. One dispatch in flight
   at a time, never a batch of tests ahead of the code. While the author runs it is the only
   writer in the tree, and it is never asked to commit.
2. Read the verdict, and record on the behaviour's build line what was done with it:
   - `RED_AS_EXPECTED`: go on.
   - `REFUSED_INCOMPLETE_INPUT`: the behaviour line was too vague to become an assertion. Sharpen
     it and dispatch again. A refusal because no one relies on the behaviour means it is
     structural: it ships with no test, and its build line says so.
   - `BLOCKED` on a missing seam: build the seam in production code first (pass the dependency
     in, return the result instead of mutating), then dispatch again. Never a mock around it.
   - `BLOCKED` naming a run command the project map lacks, a slot reading
     `none yet → /testing-policy`: the map does not change during the run, so a second dispatch
     would meet the same `BLOCKED`. The run writes this behaviour and every remaining one itself,
     under [tdd-fallback.md](tdd-fallback.md), naming the missing slot and `/testing-policy` as the
     command that would fill it, and dispatches the unit test author no more this run.
   - `GREEN` before any implementation: the behaviour already holds, or the test asserts nothing.
     Back to the author with that said.
3. Write the smallest production change that turns the test green, and run the single file with
   the single-file command from the project's facts. A mechanical red (an import path, a renamed
   symbol, a typo) is fixed by the run. Any change to an assertion, an expectation or expected
   data goes back to the test author with the reason stated as the contract ("the intended
   behaviour is X"), never as the result ("the test is catching it").
4. Refactor on green, with the suite re-run after each step. A test that goes red under a pure
   refactor was asserting the implementation and goes back to the author.
5. Typecheck, then format the touched files with the project's formatter, both from the project's
   facts; a command the project does not have reads `skip: <reason>`.
6. Commit the test, the implementation and any promotion changeset together, staged by path and
   never with `-A` or `.`. The title is a conventional commit, `type(scope): subject`, with
   `feat`, `fix`, `refactor`, `test`, `docs` or `chore`; the body carries the behaviour line,
   labelled `Behaviour: <line>` on a line of its own so that a resume reads it off the branch, and
   the single-file command that passes.
7. Next behaviour.

Done when every behaviour line has a commit beside it and its build line is recorded for the
Reply's Run section.

Under the fallback, when the loop line reads `Loop: fallback` (no unit test author
in the project and no global one that can be dispatched), the same loop runs by
[tdd-fallback.md](tdd-fallback.md), read only then: the run writes the failing test itself where
a cheap path exists, and otherwise the closest executable check with the reason stated, and no
test author is dispatched. Nothing else changes: red first, the smallest green, one commit.

## The test authors

The Testing Policy's authors write every new test. With the Agent tool, call the Agent tool with
`subagent_type: unit-test-author` for a unit test and `subagent_type: e2e-test-author` for a
flow. Without the Agent tool, call the Skill tool with `test-author` and the argument `unit` or
`e2e`, the project's inline entry point, and fill the dispatch input for yourself before writing.
The unit author returns `RED_AS_EXPECTED`, `GREEN`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`; the
E2E author returns `GREEN`, `RED`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`, and its `BLOCKED` on a
preflight is an infrastructure failure.

Under `Loop: global` the project has no Testing Policy, and the authors are the two `do` ships in
its `agents/` folder, each carrying the policy's agent core unchanged: call the Agent tool with
`subagent_type: global-unit-test-author` for a unit test and
`subagent_type: global-e2e-test-author` for a flow, with the same dispatch input and one more line,
`Project map: <the map's path>`, the file the ground step derived. Each author reads its commands
and its layout from that file, so no dispatch derives the map again, and the verdicts are the ones
above. The global authors have no inline entry point: with the Agent tool withheld the loop line
already reads `Loop: fallback`, the run writes every unit test itself by
[tdd-fallback.md](tdd-fallback.md) and authors the flow itself, and no author is dispatched.
