# The TDD fallback

How the build loop of [build-loop.md](build-loop.md) proves a behaviour when no test author can be
dispatched for it: the run writes the failing test itself.

The loop does not change: one behaviour at a time, red first, the smallest green, a refactor on
green, one commit holding the test and the implementation with the behaviour line in its body.
What changes is who writes the test. Every step build-loop.md gives to a dispatched author is the
run's own here, and the loop's verdicts hold with the run as its own author.

The fallback is a way to keep building, never a reason to stop. The run does not pause to report
it and does not ask the developer for a Testing Policy or for the Agent tool: it says on the loop
line or the build line why it is here, and carries on.

## When this file is read

Two ways in, and no other:

| The loop line | The way in | What the run writes itself |
|---|---|---|
| `Loop: fallback` | the build loop reads this file before the run writes its first test | every unit test of the run |
| `Loop: global` | build-loop.md's `BLOCKED` route: the global unit test author came back `BLOCKED` naming a run command the project map lacks | that behaviour and every one remaining |

On the `BLOCKED` route the loop line keeps reading `Loop: global`, and the run dispatches the unit
test author no more: the map does not change during the run, so a second dispatch would meet the
same `BLOCKED`.

What `Loop: fallback` means depends on the Playbook:

- `ticket`: the project has no unit test author, `.claude/agents/unit-test-author.md`, and the
  global one, `global-unit-test-author`, is not linked or the Agent tool is withheld. `ticket` is
  the only Playbook whose loop line ever reads `Loop: global`.
- `bug-fix` and `refactoring`: the project has no unit test author, and nothing more. These two
  never check for a global author, so this file is read there whether or not one is linked.

Under `Loop: policy` the project's own author is present, the Testing Policy's core is the loop
and this file is never read. Under `Loop: global` it is never read except through the `BLOCKED`
route.

## The rule

Make the behaviour executable before changing production code: a focused test that fails before
the change and passes after it. A test that was never seen red proves nothing about the change,
since it may pass for a reason that has nothing to do with it.

The feature case and the bug case follow the same rule. A new behaviour gets its failing test
first, and a defect gets the test that reproduces it before the fix. Both hold where a cheap path
exists. Where none does, the closest executable check stands in, per the section on that below.

### A cheap path

A cheap path is a test target the codepath already uses, or one the project's own runner holds
without new infrastructure:

- the unit, component or integration test the neighbouring code has;
- a script in the repository's own test folder.

A path is not cheap when it needs any of these: broad harness setup, brittle mocks, slow
end-to-end infrastructure, production-only state, vague reproduction steps, large unrelated
fixture churn.

### The commands

The commands come from the repository's own scripts (`package.json` scripts, a Makefile, a
justfile, `pyproject`) and the runner they name, the way the gate in
[mechanics.md](mechanics.md) reads them. Read them off the repository each run: a command recalled
from another repository runs the wrong runner or none, and reads as a red the code did not cause.
The single-file command is the one the commit body carries.

## The steps, per behaviour

1. Understand the behaviour: the intended behaviour, the current one, the affected path, and the
   smallest observable example, or the reproduction for a defect.
2. Choose the narrowest executable check: the closest unit, component, integration or regression
   test already used for that codepath. When no cheap path exists, take the section below
   instead of building a test path from scratch to satisfy the loop.
3. Write the failing test first: the smallest focused test that would catch the missing behaviour
   or the bug, in the caller's words. Take the expectation from the Ticket, its Spec and the
   behaviour line. An expectation read off the implementation repeats whatever the implementation
   does, the bug included.
4. Run it before any production change and read what it shows:

   | The first run | What it means | What the run does |
   |---|---|---|
   | fails for the declared reason | the loop's `RED_AS_EXPECTED` | records it on the behaviour's build line and goes on to step 5 |
   | fails for an unrelated reason (an import path, a typo, a fixture) | the test is wrong, not the code | fixes the test and runs it again, before the implementation is touched |
   | passes | the behaviour already holds, or the test asserts nothing | rewrites the test until it can fail, or records that the behaviour already holds |
   | cannot reach the behaviour without a mock around an internal | a seam is missing | builds the seam in production code first (pass the dependency in, return the result instead of mutating), then writes the test against it |

5. Write the smallest production change that satisfies the intended behaviour and preserves the
   neighbouring contracts: the least logic that makes the behaviour hold for every valid input,
   never the least code that satisfies the assertion. A constant or a branch that recognizes the
   test's own inputs is the test rewritten as code.
6. Rerun the test and read green. Then refactor on green, with the suite re-run after each step.
7. Run the nearby validation, typecheck, lint and the formatter as the loop's own steps say, and
   commit the test and the implementation together, per the record below.

## When no cheap path exists

The red step is never skipped in silence. In order:

1. Before the change, state why a failing test is impossible or not worth its cost.
2. Choose the closest executable check: a targeted script, a reproduction command, a browser
   automation, a snapshot comparison, a log assertion, a focused integration check. A manual
   verification is the last resort, when nothing scripted reaches the behaviour.
3. Run the check before the change and after it, where the check allows it.
4. Record the reason and the check, per the record below.

Prefer no new test over a bad one. A bad test costs more than a missing one, since it reads as
coverage, goes red on changes that break nothing and stays green on the bug. A test is bad when
it:

- mostly tests mocks;
- encodes implementation details;
- depends on timing or on unrelated global state;
- needs expensive infrastructure for a small change;
- would be deleted right after proving the change.

## Guardrails

- Change a test only when it is wrong about the intended behaviour, never to match what the
  implementation does: a test bent to fit the code stops proving the behaviour.
- Weaken an existing assertion only when the expected behaviour changed, and state the reason in
  the commit body. An assertion loosened without one is a guarantee dropped where nobody reads it.
- Keep the test on the behaviour, with no broad fixture churn and no unrelated coverage: the
  commit is one behaviour's checkpoint, and whatever else rides in it is trusted by the resume and
  read by the review as part of that behaviour.
- Make a flaky reproduction deterministic where possible, and name the signal being locked down,
  so a later red points at that signal and not at the timing.
- When a bug exposes a broader class of failures, land the focused regression path first, then
  take the sibling coverage as its own behaviour.

## What the run records

The reply reports evidence, not the outcome, and each line below is what a later reader has in
place of having watched the run.

| Where | What it carries |
|---|---|
| The behaviour's build line, for the Reply's Run section per [reply.md](reply.md) | that the behaviour went to the fallback and why (no author to dispatch, or the missing slot and `/testing-policy` as the command that would fill it); the `RED_AS_EXPECTED` read at step 4; when a check stood in, the reason and the check |
| The commit body | the behaviour line, labelled `Behaviour: <line>`, and the single-file command that passes; when a check stood in, the check and the reason in place of that command |
| The Reply's Evidence section | the failing-before run and the failure it produced, the passing-after run and the nearby validation, quoted; when failing-before evidence could not be shown, why, and the closest check used instead |
| The Reply's Pending debt | each behaviour where a check stood in for a test, named as that |

For example, the commit of a behaviour a check stood in for:

```
fix(export): stream the report rows instead of buffering them

Behaviour: an export of 100 000 rows finishes inside the worker's memory limit
scripts/repro-export.sh 100000
A check stood in for a test: the only path to this code is the end-to-end suite,
which needs a seeded database.
```

## Attribution and changes from upstream

Adapted from the `tdd` skill of [pstack](https://github.com/cursor/plugins/tree/main/pstack) by
Lauren Tan, MIT (see [PSTACK-LICENSE](../../../vendor/PSTACK-LICENSE)), upstream commit
`7314f723a487ec406b6369fe5865ba034cfed166`, with the frontmatter stripped and these changes:

- The frontmatter is stripped. Upstream's door, a skill used only when the user asks for TDD or the
  bug has an obvious cheap test target, is replaced by the loop line: this file is read through
  the two ways in above, never on request.
- Upstream is written for a bug fix. The feature case follows the same rule here: the failing test
  first where a cheap path exists, else the closest executable check with the reason stated.
- The workflow is folded into the build loop of `build-loop.md`: the same steps, the loop's
  verdicts, one commit per behaviour, and the reply's Evidence section in place of upstream's
  "Final Response".
- The commands come from the repository's own scripts, as the gate reads them.
- The text is laid out for the run that reads it mid-loop: the ways in and the run's records as
  tables, each guardrail with its reason, and upstream's rules on an impractical test in one
  section.
