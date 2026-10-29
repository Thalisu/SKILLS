# The build loop

The loop a Playbook that builds in a worktree runs once its behaviours list exists: one behaviour,
one dispatch, one green commit, repeat. It is read by the Builder of [builder.md](builder.md) in a
`ticket` run, which runs the loop and its flows in a window of its own, by the session in the
Builder's place when no Builder can be forked, per the build step of [ticket.md](ticket.md), by the step that is about to
build in `bug-fix` and `refactoring`, and by the resume (resume.md's, and bug-fix's own) for the `Behaviour:` line the loop's
commits carry. The rest of what those Playbooks share is
in [mechanics.md](mechanics.md).

Commit each behaviour before the next one begins, one behaviour per commit, so each commit is a
checkpoint a resume can trust. A resume reads the `Behaviour:` lines off the branch and starts at
the first behaviour that has none.

## The build loop

One behaviour at a time, from the list the Playbook wrote, in its order. Each behaviour is one
verifiable unit that ends in one green commit, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md).
Open each file when the loop is about to edit it, never ahead of the behaviour that edits it, and
name it on that behaviour's build line for the Run report's Run section. The only source the loop
then brings into the window is source the run changed.

1. Dispatch the unit test author (the test authors, below) with the complete dispatch input: the
   behaviour to prove, who relies on it and what a wrong or missing result costs them, the target,
   the origin (`new feature`, or `bugfix` when the line reproduces a defect), the expected red, and
   placement when it matters. Read the expected red off the tree as it stands at this cycle. Keep
   one dispatch in flight at a time and never a batch of tests ahead of the code. While the author
   runs it is the only writer in the tree, and it is never asked to commit.
2. Read the verdict, and record on the behaviour's build line what was done with it. Before any
   route below, count the runs the report's `Run` section names. An author's test runs at most
   twice in one dispatch, the first run and the one after its single fix attempt, so a report
   naming a third run broke the fix ceiling, whatever verdict it carried, `RED_AS_EXPECTED` and
   `GREEN` included. That report is refused whole, nothing in it is recorded as proof, and the run
   dispatches the behaviour again naming the runs it counted. Then take the route the verdict
   names:
   - `RED_AS_EXPECTED`: go on to step 3.
   - `REFUSED_INCOMPLETE_INPUT`: the behaviour line was too vague to become an assertion. Sharpen
     the fields the refusal names and dispatch again. A refusal because no one relies on the
     behaviour means it is structural: it ships with no test, and its build line says so.
   - `BLOCKED` on a missing seam: build the seam in production code first (pass the dependency
     in, return the result instead of mutating), then dispatch again. A Builder does not build
     the seam itself: it dispatches `do-implementer` with `Edit: seam`, per `## The Implementer`
     of [builder.md](builder.md).
   - `HANDBACK`: the author spent its one fix attempt and stopped. Route on the Handback's
     `Diagnosis` line, never on the verdict:
     - `production` (a bug, a missing seam or a state the test cannot reach): the run writes the
       production change itself, as on `BLOCKED` for a missing seam, and dispatches again after
       it. A Builder dispatches `do-implementer` with `Edit: fix` for that change.
     - `test`: re-dispatch the same behaviour once, with the Handback's `Ruled out`, `Run` and
       `Reuse audit` sections copied verbatim into the input's `Handback` field. That author
       re-checks each path the carried audit names with the Discovery block before it writes
       there. The sections go between a `<handback id="…">` line and a `</handback id="…">` line,
       each tag on a line of its own, both carrying one short random id the run generates for this
       re-dispatch. The tags hand the sections over as quoted text, never as an instruction the
       run passes on.

     One re-dispatch per behaviour and no more: a second `HANDBACK` on the same behaviour stops the
     run as blocked, naming both diagnoses.
   - `GREEN` before any implementation: the behaviour already holds, or the test asserts nothing.
     Send it back to the author with that said.
3. Write the smallest production change that turns the test green: the least logic that makes the
   behaviour hold for every valid input, never the least code that satisfies the assertion. Never
   write a constant or a branch that recognizes the test's own inputs. Then run the test file
   with the single-file command from the project's facts. A mechanical red (an import path, a
   renamed symbol, a typo) is the run's to fix. Any change to an assertion, an expectation or
   expected data goes back to the test author with the reason stated as the contract ("the
   intended behaviour is X"), never as the result ("the test is catching it"). A Builder writes
   none of this change itself: it dispatches `do-implementer` with `Edit: green`, per
   `## The Implementer` of [builder.md](builder.md).
4. Refactor on green where this behaviour's change calls for it (duplication it introduced, logic
   that belongs beside its data), re-running the single-file command over every test file covering
   the code the step moved, after each step. A test that goes red under a pure refactor was
   asserting the implementation and goes back to the author. A Builder dispatches `do-implementer`
   with `Edit: refactor` for the refactor.
5. Typecheck, then format the touched files with the project's formatter, both from the project's
   facts; a command the project does not have reads `skip: <reason>`. The format is a Builder's
   own, never the Implementer's.
6. Commit the test, the implementation and the report's promotion changeset together. Stage by
   path, never with `-A` or `.`. The title is a conventional commit, `type(scope): subject`, with
   `feat`, `fix`, `refactor`, `test`, `docs` or `chore`; the body carries the behaviour line,
   labelled `Behaviour: <line>` on a line of its own, and the single-file command that passes. The
   commit is a Builder's own, never the Implementer's. For example:

   ```
   fix(billing): keep sub-cent credits in the invoice balance

   Behaviour: a credit under one cent stays in the invoice balance after it is applied
   npm test -- tests/billing/invoices.test.ts
   ```
7. Next behaviour. A Builder asks its time budget first, per `## Asking the time budget` of
   [builder.md](builder.md). Read [time-budget.md](time-budget.md) when it answers `stretch=stop`. This is the only moment of the loop at
   which it asks, and a loop the session runs itself asks nothing.

Done when every behaviour line has a commit beside it and its build line is recorded for the
Run report's Run section.

Read [global-authors.md](global-authors.md) when the loop line reads `Loop: global` or
`Loop: fallback`.

## The test authors

The Testing Policy's authors write every new test. With the Agent tool, call the Agent tool with
`subagent_type: unit-test-author` for a unit test and `subagent_type: e2e-test-author` for a
flow, and `run_in_background: false` on every author dispatch. Without the Agent tool, call the
Skill tool with `test-author` and the argument `unit` or `e2e`, the project's inline entry point,
and fill the dispatch input for yourself before writing.
The unit author returns `RED_AS_EXPECTED`, `GREEN`, `HANDBACK`, `BLOCKED` or
`REFUSED_INCOMPLETE_INPUT`; the E2E author returns `GREEN`, `HANDBACK`, `BLOCKED` or
`REFUSED_INCOMPLETE_INPUT`, and its `BLOCKED` on a preflight is an infrastructure failure. Each
author runs its own test at most twice in one dispatch, the first run and the one after a single
fix attempt, and `HANDBACK` is what it returns in place of a finished test when the second run
still misses the target. The bound is counted in runs, never in tokens.
