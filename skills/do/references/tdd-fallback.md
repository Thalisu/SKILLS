# The TDD fallback

Adapted from the `tdd` skill of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by
Lauren Tan, MIT (see [PSTACK-LICENSE](../../../vendor/PSTACK-LICENSE)), upstream commit
`7314f723a487ec406b6369fe5865ba034cfed166`, with the frontmatter stripped and the changes listed at
the end.

The build loop of [build-loop.md](build-loop.md) reads this file when the loop
line reads `Loop: fallback`, and it has a second way in that leaves the loop line reading
`Loop: global`: build-loop.md's `BLOCKED` route, taken when the global unit test author comes back
`BLOCKED` naming a run command the project map lacks (the map does not change during the run, so a
second dispatch would meet the same `BLOCKED`), which reads this file from there for that
behaviour and every one remaining, and dispatches the unit test author no more this run.
The `ticket` Playbook is the only one whose loop line ever reads `Loop: global`, read when the
project has no unit test author, `.claude/agents/unit-test-author.md`, and the global one,
`global-unit-test-author`, is linked and the Agent tool is present; `Loop: fallback` is read
otherwise, `global-unit-test-author` not linked or the Agent tool withheld:
with the project's own author present, the Testing Policy's core is the loop and this file
is never read; with the global author present, this file is never read except through the
`BLOCKED` route above.
`bug-fix` and `refactoring` never check for a global author and never set `Loop: global`:
their `Loop: fallback` means only that the project has no unit test author, and this file
is read there whether or not a global one is linked.
The loop does not change: one behaviour at a time, red first, the smallest green, a refactor on
green, one commit holding the test and the implementation with the behaviour line in its body.
What changes is who writes the test. The run writes the failing test itself, and
no test author is dispatched, since none can be.

## The rule

Make the behaviour executable before changing production code: a focused test that fails before
the change and passes after it. The feature case and the bug case follow the same rule. A new
behaviour gets its failing test first where a cheap path exists, and a defect gets the test that
reproduces it before the fix. Where no cheap path exists, the closest executable check stands in,
with the reason recorded on the behaviour's build line for the Reply's Run section, per
[reply.md](reply.md), and stated in the commit body.

A cheap path is a test target the codepath already uses, or one the project's own runner holds
without new infrastructure: the unit, component or integration test the neighbouring code has, or
a script in the repository's own test folder. A path is not cheap when it needs broad harness
setup, brittle mocks, slow end-to-end infrastructure, production-only state, vague reproduction
steps or large unrelated fixture churn.

The commands come from the repository's own scripts (`package.json` scripts, a Makefile, a
justfile, `pyproject`) and the runner they name, the way the gate in
[mechanics.md](mechanics.md) reads them, never from memory of another repository. The single-file
command is the one the commit body carries.

## The steps, per behaviour

1. Understand the behaviour: the intended behaviour, the current one, the affected path, and the
   smallest observable example, or the reproduction for a defect.
2. Choose the narrowest executable check: the closest unit, component, integration or regression
   test already used for that codepath. When no practical test path exists, do not build one from
   scratch to satisfy the loop. Record why on the behaviour's build line and pick the closest executable check: a
   targeted script, a reproduction command, a browser automation, a snapshot comparison, a log
   assertion, a focused integration check.
3. Write the failing test first: the smallest focused test that would catch the missing behaviour
   or the bug. It encodes the intended behaviour in the caller's words. The expectation comes from
   the Ticket, its Spec and the behaviour line, never from reading the implementation.
4. Run it before any production change and confirm it fails for the declared reason. This is the
   loop's `RED_AS_EXPECTED`, recorded on the behaviour's build line. A pass, or a failure for an unrelated reason (an
   import path, a typo, a fixture), is corrected in the test before the implementation is touched.
5. Write the smallest production change that satisfies the intended behaviour and preserves the
   neighbouring contracts.
6. Rerun the test and read green. Then refactor on green, with the suite re-run after each step.
7. Run the nearby validation, typecheck, lint and the formatter as the loop's own steps say, and
   commit the test and the implementation together, the behaviour line and the single-file command
   in the body. When a check stood in for a test, the body names the check and the reason.

## When a failing test is impractical

Never skip the red step in silence. Before the change, state why a failing test is impossible or
not worth its cost, then choose the closest executable check and run it before and after where the
check allows it. Prefer no new test over a bad test: one that mostly tests mocks, encodes
implementation details, depends on timing or unrelated global state, needs expensive
infrastructure for a small change, or would be deleted right after proving the change. The reason
goes on the behaviour's build line for the Reply's Run section and in the commit body, and the reply
lists the behaviour under Pending debt as
a check that stood in for a test.

## Guardrails

- Never change a test to match a wrong implementation.
- Never weaken an existing assertion unless the expected behaviour changed and the reason is
  stated.
- Keep the test on the behaviour: no broad fixture churn, no unrelated coverage.
- Do not add a test when the practical signal is weak. Use a scripted or manual verification and
  record why on the behaviour's build line.
- Make a flaky reproduction deterministic where possible, and name the signal being locked down.
- When a bug exposes a broader class of failures, land the focused regression path first, then
  consider sibling coverage as its own behaviour.
- The loop's verdicts hold with the run as its own author. A red for the wrong reason is fixed in
  the test. Green before any implementation means the behaviour already holds or the test asserts
  nothing, and the test is rewritten. A missing seam is built in production code first, never
  mocked around.

## In the reply

Evidence, not the outcome: the failing-before run and the failure it produced, the passing-after
run and the nearby validation, and, when failing-before evidence could not be shown, why, and the
closest check used instead. These are the lines the reply's Evidence section quotes.

## Changes from upstream

- The frontmatter is stripped. Upstream's door, a skill used only when the user asks for TDD or the
  bug has an obvious cheap test target, is replaced by the loop line: this file is read when the
  loop line reads `Loop: fallback`, never on request.
- Upstream is written for a bug fix. The feature case follows the same rule here: the failing test
  first where a cheap path exists, else the closest executable check with the reason stated.
- The workflow is folded into the build loop of `build-loop.md`: the same steps, the loop's
  verdicts, one commit per behaviour, and the reply's Evidence section in place of upstream's
  "Final Response".
- The commands come from the repository's own scripts, as the gate reads them.
