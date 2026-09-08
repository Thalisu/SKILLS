# Shared mechanics

One file for the parts the Playbooks that build in a worktree share, read by `ticket`, `bug-fix`
and `refactoring`, so a fix to a mechanic is made once. It carries the worktree, the protected
branch, the Ticket file, the build loop with its test authors, the gate, the review and the
verification. A Playbook links the section it needs and never copies it.

## The worktree

Every build runs in a git worktree the run creates itself from the current HEAD, never through a
tool that branches from the remote default branch.

1. In the main checkout, read the branch and `git status --short`. The dirty files are the
   developer's work in progress: nothing in the run edits, stages or reverts them, and the
   worktree starts from HEAD without them.
2. Create it from the main checkout: `git worktree add .claude/worktrees/do-<slug> -b do/<slug>`,
   where `<slug>` is the Ticket's slug, or the request's outside the chain. `.claude/worktrees/`
   is the harness's worktrees folder, the one place a harness worktree tool accepts a switch
   into; any path works where there is no such tool.
3. Keep the main checkout's status as the developer left it: when
   `git check-ignore -q .claude/worktrees` fails, append `.claude/worktrees/` to
   `.git/info/exclude`. Never to the project's `.gitignore`: the ignore file is the project's,
   the exclude list is this clone's.
4. Enter it: the run's working directory changes to the worktree. Where the harness has a
   worktree tool that accepts an existing path, that tool makes the change; otherwise `cd` does.
   Every command from here runs in the worktree, and the main checkout is reached by its own path
   when a step needs it.
5. Done when `git status --short` in the worktree prints nothing and the branch name is in the
   thread.

The worktree stays until the run's work has landed and its affected flows are green. The run
removes it and its branch itself, from the main checkout, since a harness tool removes only the
worktrees it created; a run that stops as blocked leaves both in place and names them in the
reply. One writer at a time in the worktree, per
[separate-before-serializing-shared-state](../../../.agents/principles/separate-before-serializing-shared-state.md):
the session, or the test author it dispatched while that author runs.

## The protected branch

The rule is the one `test-triage` uses: `main` or `master` is protected when `develop`,
`development`, `staging` or `release*` exists locally or on a remote; `production` or `prod` is
protected when any of those or `main` or `master` exists; a default branch that is the only
branch is the working branch. Nothing lands on a protected branch. A Playbook checks the
developer's branch against it before the work starts and says in its first message that landing
will be refused, so the developer switches before the work and not after.

## The Ticket file

The Ticket belongs to the main checkout, whether git tracks it, ignores it or has never seen it.
It is read and edited there, by its path in the main checkout, in the format of
[ticket-format.md](../../../.agents/formats/ticket-format.md), and only there: the worktree
branch never touches it and the run never commits it. A worktree created from HEAD has no copy
of an untracked Ticket, and a claim written in the main checkout beside an edit of the same file
on the branch makes the landing fast-forward fail, so one rule covers the three states.

- The claim is the `**Status:**` line set to `claimed`, written before the worktree exists. On a
  remote tracker the claim is the issue assigned to the developer, the way the tracker file
  describes, made after the developer's yes.
- During the build the file is read and never written: the criteria and the `What to build` line
  are where the behaviours come from.
- The status walk and who writes each word are the format's. The run writes `claimed` at the
  start and `resolved` at the close, and nothing in between. With `resolved` it writes the
  `Context:` line the format defines as the first line under `## Evidence`, from two readings of
  `bash <skill-dir>/scripts/context-usage.sh`: the `current` figure read at the end of the ground
  step, written as `grounded`, and the `peak` and `band` read at the close, after the last edit. A
  reading that exits non-zero writes `Context: not measured` with the script's reason.

## The build loop

One behaviour at a time, from the list the Playbook wrote, in its order. Each behaviour is one
verifiable unit that ends in one green commit, per
[sequence-verifiable-units](../../../.agents/principles/sequence-verifiable-units.md).

1. Dispatch the unit test author (the test authors, below) with the complete dispatch input: the
   behaviour to prove, the target, the origin (`new feature`, or `bugfix` when the line
   reproduces a defect), the expected red, and placement when it matters. One dispatch in flight
   at a time, never a batch of tests ahead of the code. While the author runs it is the only
   writer in the tree, and it is never asked to commit.
2. Read the verdict, and say in one line what was done with it:
   - `RED_AS_EXPECTED`: go on.
   - `REFUSED_INCOMPLETE_INPUT`: the behaviour line was too vague to become an assertion. Sharpen
     it and dispatch again.
   - `BLOCKED` on a missing seam: build the seam in production code first (pass the dependency
     in, return the result instead of mutating), then dispatch again. Never a mock around it.
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

Done when every behaviour line has a commit beside it.

Under the fallback, when the project has no unit test author, the same loop runs by
[tdd-fallback.md](tdd-fallback.md), read only then: the run writes the failing test itself where
a cheap path exists, and otherwise the closest executable check with the reason stated, and no
test author is dispatched. Nothing else changes: red first, the smallest green, one commit.

### The test authors

The Testing Policy's authors write every new test. With the Agent tool, call the Agent tool with
`subagent_type: unit-test-author` for a unit test and `subagent_type: e2e-test-author` for a
flow. Without the Agent tool, call the Skill tool with `test-author` and the argument `unit` or
`e2e`, the project's inline entry point, and fill the dispatch input for yourself before writing.
The unit author returns `RED_AS_EXPECTED`, `GREEN`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`; the
E2E author returns `GREEN`, `RED`, `BLOCKED` or `REFUSED_INCOMPLETE_INPUT`, and its `BLOCKED` on a
preflight is an infrastructure failure.

### Forks

A question is classified before it is asked. An empirical fork (which timing, which output,
whether an API does the thing) is a fact a script can observe: it is settled by a throwaway probe
script in the worktree, deleted before the commit, and never reaches the developer, per
[never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md). A design
fork (two shapes the Ticket, its Spec and the code cannot settle) means the Spec is incomplete:
the run stops at its step with one message naming `discuss`, the Ticket left `claimed` and the
worktree in place, so that the next `/do` on the Ticket resumes it once the Spec is amended.

### Delegates

The session writes the production code and commits. A delegate is forked by exception, per
[the ADR](../../../docs/adr/0009-the-session-writes-a-delegate-is-the-exception-and-no-playbook-depends-on-nesting-depth.md):
for bulk mechanical work with a closed scope, after a script was considered per
[build-the-lever](../../../.agents/principles/build-the-lever.md), or for exploration whose
output would flood the thread per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md), and never
while a test author runs. It gets file pointers and the named shape instead of inlined context,
and may dispatch its own test author. When the Agent tool is withheld from it, it writes nothing
and says so, and the session does that work itself. The session reads the delegate's diff and
writes its own summary; the delegate's summary is never passed through.

## The gate

Run in the worktree after the last edit, never earlier, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): the full unit suite, the
typecheck, the lint and the format check. "Passed earlier" is stale; a check that ran before the
last edit runs again.

The commands come from the project's facts, the Testing Policy's Project facts in `CLAUDE.md`. A
command the facts do not carry comes from the repository's own scripts (`package.json` scripts, a
Makefile, a justfile, `pyproject`), never from memory of another repository, and a check with
nothing to run reads `skip: <reason>`. Each command line is shown before it runs and the relevant
output line is quoted after.

- Red: back to the build loop as one more unit, then the whole gate again. Never a skipped test,
  a weakened assertion or a sleep.
- Output that describes the environment and not the code (a connection refused, a service down, a
  runner that cannot start) is an infrastructure failure. The run stops as blocked, names the
  cause and never works around it. Only the developer can waive it, and a waiver is recorded as
  debt in the reply, never as green.
- A tool timeout is "did not finish", neither red nor green: the command line is reported and the
  run stops.

Done when the suite and the typecheck are green in output produced after the last edit, and every
other check is green or reads `skip: <reason>`.

## The review

Run once per landing, after the gate, and never by hand: the review fixes and lands, the run reads.
Call the Skill tool with `do-code-review` and three arguments: the spec source (the Ticket's
location in `ticket`, so the Review lands beside it; the branch alone in `bug-fix` and
`refactoring`), the fixed point of the branch under review (the commit the worktree was created
from, or the commit the review last landed), and the developer's branch as the landing target.
Never `fix`, never `--no-fix`: the default run is the one every Playbook wants, per ADR 0015. The
run waits on the call. While the review runs, its Fixer is the only writer in the worktree, and
the run touches nothing.

What the review does with the call, so that the run does not: it writes the Review, forks its
Fixer with the `Act on` list, which turns every `Act on` Finding into one commit on the reviewed
branch under the project's Testing Policy, re-runs each Finding's check and the gate, and, when
the Review is Green, lands the reviewed branch on the developer's branch by fast-forward under the
landing rules of ADR 0013: a protected branch refused, the branch rebased first when the
developer's branch moved, a rebase conflict aborted with the conflicting files named, a failed
fast-forward left in place, nothing pushed.

The run reads the outcome off the return and never opens the Review file. The thread shows the
return, one line per part:

- the Review's location;
- the landing line, `landed at <commit>`, or `not landed` with the review's reason;
- the Fixer's commits, one per `Act on` Finding, by the Finding's number;
- every `Consider` Finding, the ones carrying a risk class flagged to the developer, since a
  risk class is never dismissed silently;
- an Axis marked `not run`, named to the developer with its reason.

The run makes no commit for a Finding and fixes none by hand: a Finding the Fixer left standing
is the review's reason for not landing, and the run stops on it. Landed, and the run goes on to
the verification. Not landed, for any reason the review gives (a Finding `not fixed` or
`not verified`, an Axis `not run`, a red gate after the fix, a rebase conflict, a failed
fast-forward, a protected branch), and the run stops as blocked: the review's reason quoted, the
worktree and its branch left in place and named in the reply, the Ticket left `claimed`, so that
nothing lands half fixed. On a protected branch the reply adds the two commands that land the
reviewed branch by hand from a branch that takes commits, since the diff was reviewed and Green
and only the target was wrong:

```
git switch <a branch that takes commits>
git merge --ff-only do/<slug>
```

When the session does not list `do-code-review`, the step reads
`skip: do-code-review not listed`: nothing lands, the worktree and its branch stay in place and
are named in the reply, and the reply names the review and the landing as the developer's next
step.

## The verification

Run from the main checkout after the landing, per
[prove-it-works](../../../.agents/principles/prove-it-works.md): the work is on the developer's
branch now, and Project facts may say the E2E stack serves the primary checkout. The commands run
there, the checkout reached by its path; the worktree stays, since it is where a red flow is fixed.

1. The affected flows are the flow the E2E step authored or extended and every existing flow over
   a screen, a route or a message the diff changed. Each runs with the single-flow command from
   the project's facts, the command line printed before it runs and the relevant output line
   quoted after. A change the E2E step called internal, with no user-observable surface, has no
   affected flow: the step reads `skip: no affected flow` with that reason.
2. A full suite or a remote run waits for the developer's yes, the command line shown first. It is
   the only question asked on this path, per
   [never-block-on-the-human](../../../.agents/principles/never-block-on-the-human.md), because
   its cost is the one thing only the developer can weigh. A no records each flow that needed it
   as not run, leaves the criterion it would have proven unticked, and records the waiver as debt
   in the reply; the close still happens.
3. An infrastructure failure (a service down, a runner that cannot start, a device missing) stops
   the run as blocked with the cause named and is never worked around; only the developer can
   waive it, and the waiver is debt in the reply, never green.

Done when every affected flow is green in output produced after the last landing, or recorded as
not run on the developer's no, with every command line in the thread.
