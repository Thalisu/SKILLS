# Shared mechanics

One file for the parts the Playbooks that build in a worktree share, read by `ticket`, `bug-fix`
and `refactoring`, so a fix to a mechanic is made once. It carries the worktree, the protected
branch, the Ticket file, the reader, the build loop with its test authors, the gate, the review,
the verification and the close. A Playbook links the section it needs and never copies it.

## The worktree

Every build runs in a git worktree the run creates itself from the current HEAD, never through a
tool that branches from the remote default branch.

1. Prove the run starts in the main checkout before anything is created:
   `git rev-parse --show-toplevel` and the first entry of the worktree list, the derivation
   [worktrees.md](../../../.agents/worktrees.md) carries, are the same path. Two paths mean the
   session sits in a linked worktree, which the harness's worktree tool is the likely reason for,
   and the run builds nothing from there: it leaves the isolation the way that file says, or moves
   to the main checkout with a bare `cd` when nothing isolated it, and starts this step over.
   Then, there, read the branch and `git status --short`. The dirty files are the developer's work
   in progress: nothing in the run edits, stages or reverts them, and the worktree starts from
   HEAD without them.
2. Create it from the main checkout: `git worktree add .claude/worktrees/do-<slug> -b do/<slug>`,
   where `<slug>` is the Ticket's slug, or the request's outside the chain. `.claude/worktrees/`
   is the harness's worktrees folder: the run's worktrees sit beside the harness's own, one
   exclude line covers them all, and a resume knows where to look.
3. Keep the main checkout's status as the developer left it: when
   `git check-ignore -q .claude/worktrees` fails, append `.claude/worktrees/` to
   `.git/info/exclude`. Never to the project's `.gitignore`: the ignore file is the project's,
   the exclude list is this clone's.
4. Enter it with `cd <path>`, in a shell call of its own, per
   [worktrees.md](../../../.agents/worktrees.md): the harness keeps the working directory across
   calls, so every command from here runs in the worktree, and git reaches the main checkout with
   `git -C <its path>` when a step needs it. Never the harness's worktree tool: it isolates the
   session, and an isolated session refuses git against the main checkout, which the Ticket, the
   landing, the flows and the worktree's removal all need. The skill file denies that tool, so the
   run meets it as a refusal rather than as a rule to remember.
5. Done when one call in the worktree prints the main checkout's top level, the branch and an empty
   status, on one line:
   `git -C <main checkout> rev-parse --show-toplevel && git branch --show-current && git status --short`.
   The first of the three is the probe, and it is the backstop for step 1: a session that was
   already isolated when the run started refuses this call, for the redirect or for the shape, and
   that refusal is the state and not the command. The run has by then created a worktree from the
   isolated tree and not from the developer's HEAD, so it leaves the isolation the way
   [worktrees.md](../../../.agents/worktrees.md) says, removes the worktree and the branch it made
   there, and starts this section over from step 1. Catching that state at step 1 costs nothing;
   catching it here costs one worktree; catching it at the landing costs the build.

The worktree stays until the run's work has landed and its affected flows are green. The run
removes it and its branch itself, from the main checkout; a run that stops as blocked leaves both
in place and names them in the reply. One writer at a time in the worktree, per
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

## The reader

The Ticket's Spec and its journey are read by a fork, never by the session: they are two whole
documents the run needs a slice of, which is the exploration the Delegates rule below forks for.
The session opens neither document, and it opens neither afterwards to check the fork: what comes
back is quoted with the location of every quote, so the check is a quote read against its line.

The fork is dispatched with the brief [digest.md](digest.md) fixes and nothing else, that file's
own list and never a second one here: a copy of the list in this file drifts from the brief the
fork is actually handed. It writes the Digest at the path that brief names and returns that
location and the one line the run restates in the thread. No other part of either document reaches
the session.

The session opens the Digest itself, at the path the fork returns, and reads its quotes there. The
line that comes back with the path is a restatement for the thread: a list written from it would be
the paraphrase the Digest exists to keep out of the record, so the steps that build on the slice
read the file.

When the Agent tool is withheld from the session there is no fork to dispatch. The Delegates rule
below is what holds: the fork writes nothing and says so, and the session does that work itself. It
reads both documents, writes the Digest at the same path in the same format, and says so in one
line. It neither stops nor asks for the tool, since the developer cannot hand one over mid-run and
the slice is what the run needs, not the window it was read in.

A Ticket whose Spec or journey is not on disk still builds. The reader records the document as
absent and quotes nothing under its section, and the run continues from the Ticket alone, saying so
in one line naming the document that is absent. Only the Ticket's criteria and its `What to build`
line feed the behaviours list then, and the line of the list that would have traced to a quote in
that document traces to the criterion instead.

The door reads `git status --short` in the main checkout before it dispatches the fork, after its
own append of the `.scratch/` line, and reads it again when the fork returns. That read is blind to
the scratch the line it just appended ignores, and the Digest and its neighbours live there, so the
door takes a second reading beside it, `git status --short --ignored -- .scratch/` and the
`git hash-object` of every file that read lists, before the fork and again after.
The Digest's path is the only one that may differ, in either reading.
Any other path stops the run in one line naming it, the Ticket left as the door found it. The brief
is the only thing bounding what the fork touches, so the door checks it rather than trusting it.

### A second run

A Digest already sits beside the Ticket whenever a run reaches this point a second time, on a
resume or on a `/do` typed again on the same Ticket. Before it dispatches anything the door
resolves both paths from the Ticket itself and never from the Digest: the Spec is the spec file in
the folder above the Ticket's `issues/` folder, and the journey is the one that Spec's `Journey:`
line names. Then it recomputes the hash of each document at the path it resolved, with the same
`git hash-object` the reader ran, and compares the pair with the pair the Digest's `## Sources`
records.

- Both match: the run reuses it, forks no second reader, and says in one line that it reused it.
- Either differs: the run re-forks the reader over both documents, replacing the Digest at the same
  path, and names which of the two changed, in one line.

Both hashes are compared before the run decides, never one and then the other: a comparison that
stopped at the first match would serve an amended Spec, or an amended journey, from the slice the
first run cut. A document recorded `absent` and still not on disk is a match, since nothing about
it moved; a document that appeared where the record says `absent`, one that is gone where the
record carries a hash, and a `## Sources` line the Digest does not carry are each not a match: the
run re-forks.

A `## Sources` path that is not the path the door resolved is not a match either. Both the path and
the hash on that line come out of the file the comparison is there to vouch for, so a Digest naming
a document this Ticket does not reach for is a Digest cut from somewhere else, or one steered by a
document a stranger wrote, and the run re-forks over the resolved paths rather than serving it.

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

## The integration

Run in the worktree after a green gate and before the review is called, so that the diff the
reviewers read is the diff that lands. The run rebases the branch it built on onto the developer's
branch, the branch the run started on, and nothing is written to the developer's branch: the branch
that moves is the run's. A protected developer branch does not stop this step, since a rebase onto
a branch writes nothing to it and this step lands nothing. The landing stays the review's, and a
protected target is refused there as it is refused today. The run records the commit its branch is
on before the rebase starts: the command that undoes the rebase is not the same once the rebase has
finished, and the recorded commit is what the later one names.

The step walks one of four states, and the thread says which.

**A rebase that replays no commit.** The developer's branch did not move under the run. The run
ticks the step as a no-op, reruns nothing, and the review is called on the branch as it is.

**A rebase that replayed commits.** The run ticks the step with the target and the count, the
branch it rebased onto and how many of its own commits git replayed. The gate that was green before
the replay is stale, since the run's commits now sit on code the branch had not seen: the gate's
command lines run a second time, each shown before it runs and its output line quoted after, and a
green gate calls the review on the rebased diff.

**A red gate after a rebase that replayed commits.** The run stops as blocked, the way a red gate
after the review's fix run does and never back to the build loop: the replay brought in code the
developer's branch carries, and a run that loops on it edits their work. The reply carries the
failing check named, the command that undoes the rebase, `git reset --hard <the commit recorded
before it started>`, the worktree and its branch left in place and named, the Ticket left
`claimed`, nothing landed and nothing pushed.

**A rebase that stopped.** At every stop of the rebase, before anything else, the run classes the
conflicted hunks: `bash <skill-dir>/scripts/conflict-class.sh`, whose verdict is the class, never
the session's own reading of the markers, per
[ADR 0028](../../../docs/adr/0028-the-conflict-class-is-a-scripts-verdict-never-the-sessions-reading.md).
The run shows the lines it printed, one per conflicted hunk, and states the counts before it does
anything: how many hunks it resolved mechanically and how many it is bringing to the developer.

Where every hunk of the stop is `mechanical`, the run resolves them itself and nothing is asked of
the developer. For each conflicted file it takes the three stages out of the index and writes their
union:

```
git show :1:<path> > <base> && git show :2:<path> > <target> && git show :3:<path> > <incoming>
git merge-file --union -p <target> <base> <incoming> > <path>
```

Stage 2 is the developer's branch and stage 3 the commit being replayed, so the union in that order
keeps both sides with the developer's branch above the replayed commit's, which is the base order
this step owes. Git writes the result and the session never edits a marker. Then `git add <path>`
marks the file resolved, `git rebase --continue` carries the rebase to the next commit, and every
further stop is classed and resolved the same way. The reply names every hunk it resolved with its
file and location.

## The review

Run once per landing, after the gate, and never by hand: the review fixes and lands, the run reads.
Call the Skill tool with `do-code-review` and three arguments: the spec source (the Ticket's
location in `ticket`, so the Review lands beside it; the branch alone in `bug-fix` and
`refactoring`), the fixed point of the branch under review (the commit the worktree was created
from, or the commit the review last landed), and the developer's branch as the landing target.
Never `fix`, never `--no-fix`: the default run is the one every Playbook wants, per
[ADR 0015](../../../docs/adr/0015-the-default-review-run-fixes-and-lands-and-the-fixer-corrects-for-every-caller.md).
The run waits on the call. While the review runs, its Fixer is the only writer in the worktree, and
the run touches nothing.

A return that reads
`the session is isolated in a worktree, so the door cannot run; nothing reviewed`
reviewed nothing and wrote nothing: the door of the review is a script, and the guard of an
isolated session refuses to run one. It is not a Finding and not a refusal of the diff. The run
leaves the isolation per [worktrees.md](../../../.agents/worktrees.md) and calls the review again,
once, with the same three arguments.

What the review does with the call, so that the run does not: it writes the Review, forks its
Fixer with the `Act on` list, which turns every `Act on` Finding into one commit on the reviewed
branch under the project's Testing Policy, re-runs each Finding's check and the gate, and, when
the Review is Green, lands the reviewed branch on the developer's branch by fast-forward under the
landing rules of [ADR 0013](../../../docs/adr/0013-do-code-review-lands-a-green-review-by-fast-forward.md):
a protected branch refused, the branch rebased first when the
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
there, per [worktrees.md](../../../.agents/worktrees.md): git with `-C <the main checkout>`, any
other command after a bare `cd` to it and a bare `cd` back to the worktree; the worktree stays,
since it is where a red flow is fixed.

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

4. A red flow is a defect in the landed work, not in the flow: it is fixed in the worktree as one
   more unit of the build loop, with origin `bugfix` and the flow's failure as the expected red,
   the gate run again, and the branch handed to a second review call with the landed commit as
   its fixed point, which lands it again. A second call that returns not landed stops the run
   the way the first one does.
Done when every affected flow is green in output produced after the last landing, or recorded as
not run on the developer's no, with every command line in the thread.

## The close

After the verification, in the main checkout's Ticket file and nowhere else, per the Ticket file
above: the run never commits it and the worktree branch never touches it.

1. Tick each criterion the evidence proves, and only those: a criterion whose flow the developer
   waived stays unticked. The evidence is the run's own output, produced after the last edit.
2. Append the evidence under `## Evidence`, the last heading of the format, added first when the
   Ticket was published without it. The first line is the `Context:` line, from the `current`
   figure kept at the ground step and a second reading of `scripts/context-usage.sh` now, for
   the `peak` and the `band`; a reading that fails writes `Context: not measured` with the
   script's reason. Then the landed commit, the Review's location, the command lines of the gate
   and the flows with their quoted output lines, and each waiver.
3. Set the `**Status:**` line to `resolved`. The file stays uncommitted, for the developer, and
   the reply lists it beside the Review under the files left uncommitted.
4. On a remote tracker the run asks first, per the tracker file: on the developer's yes it
   comments the evidence on the issue and closes it; a no leaves the issue open, with the
   evidence in the reply only.
5. Remove the worktree and its branch: the run created them, so the run removes them. Leave the
   worktree first, with a bare `cd` to the main checkout, then, from there,
   `git worktree remove <path>` and `git branch -d do/<slug>`. The branch landed, so the delete is
   safe; a delete that refuses means something did not land, and the run stops there with the
   worktree and its branch named.

Outside the chain there is no Ticket: the close is the worktree's removal alone. A run that stops
as blocked closes nothing: the Ticket stays `claimed`, the worktree and its branch stay in place,
and the reply names them.
