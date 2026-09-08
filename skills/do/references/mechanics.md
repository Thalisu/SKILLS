# Shared mechanics

One file for the parts the Playbooks that build in a worktree share, read by `ticket`, `bug-fix`
and `refactoring`, so a fix to a mechanic is made once. It carries the worktree, the protected
branch, the Ticket file, the build loop with its test authors, and the gate. A Playbook links the
section it needs and never copies it.

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

Under the fallback, when the project has no unit test author, the same loop runs with the run
writing the failing test itself where a cheap path exists, and otherwise the closest executable
check with the reason stated. Nothing else changes: red first, the smallest green, one commit.

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
