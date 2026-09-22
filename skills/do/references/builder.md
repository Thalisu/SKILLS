# The Builder

The fork that builds one Ticket, from the Plan the session verified, in the worktree the session
cut, per
[ADR 0047](../../../docs/adr/0047-the-ticket-run-forks-a-planner-then-a-builder-and-the-session-stops-writing-code.md).
It is forked by the build step of [ticket.md](ticket.md) and by nobody else, a sibling of the
Planner and one layer below the session, so the test author it dispatches sits two layers down and
never three.

What it leaves behind is commits on a branch. The build's reading, the code it wrote, the tests it
ran and the output it read all stay in its window: the grounding is what a run pays for over and
over, and a session that carries the build as well compacts before the Ticket is done, per
[guard-the-context-window](../../../.agents/principles/guard-the-context-window.md).

## The brief

The fork is the `do-builder` agent `do` ships in [do-builder.md](../agents/do-builder.md), and it
is dispatched with these and nothing else, since it opens what it needs itself:

```
Ticket: <the absolute path in the main checkout, or the tracker reference>
Criteria: <the Ticket's checklist, verbatim>
Digest: <the absolute path in the main checkout> | none
Plan: <the absolute path of the Plan the session verified>
Rulings: <the `settled` Ruling lines that govern this build, one per line, or none>
Repository root: <the main checkout's absolute path>
Tree: <the worktree the build runs in>
Branch: <the branch its commits land on>
Loop: policy | global | fallback
Project map: <the absolute path `project-map.sh` printed> | none
Flow: ticket | bug-fix | refactoring
Agents folder: <the absolute path of the chain's `.agents/` folder>
```

The keys are written here and in no second place. The session fills them from this file and the
fork reads them from this file, so neither the build step of [ticket.md](ticket.md) nor
[do-builder.md](../agents/do-builder.md) carries a copy of the list: a list copied into two files
drifts, the session fills the copy, the fork reads the original, and a key that moved in one of
them is a Builder dispatched without it. It is the rule [plan.md](plan.md) already holds for the
Planner's own keys.

The brief carries no behaviours list, no position to resume from and no hash. The behaviours are
the Plan's, which the fork opens itself; the position is the branch's, which it reads off the
commits; and the hashes were checked by the session before the fork, per
[ADR 0048](../../../docs/adr/0048-a-fork-writes-its-own-artifact-and-the-session-verifies-the-header-it-computed.md),
so a fork that recomputed one would be vouching for its own grounding.

The brief is the same on the first fork and on every re-fork. Nothing in it says where to pick up,
so a Builder forked again after a Ruling, or after a reason the session cleared, reads the branch
and carries on from there. A key that differed between the first fork and a later one would be a
second thing to keep in step with the branch, and the two would drift the first time one of them
was forgotten.

## The return

The return's first line is the verdict, and the session routes on that line alone: `built`, `fork`
or `stopped`. Anything else coming back first is a return the build step cannot route, and the
stretch is picked up from `resume-state.sh` instead.

A stretch that finished:

```
built
behaviour: <the Plan's behaviour line, verbatim> | <commit>
build: <the files the loop opened> | <the author's verdict and what was done with it> | <commit>
flow: <the observable criterion> | <commit>
fallback: <what fell back and why>
```

One `behaviour:` line and one `build:` line per behaviour, in the order built, each ending in the
commit that closed it, and one `flow:` line per observable criterion the flows earned. They are the
Reply's Behaviours list and its Build lines already written, per [reply.md](reply.md), so the
session copies them and never composes them from a build it did not see.

A stretch that stopped on a Design fork:

```
fork
behaviour: <the Plan's behaviour line, verbatim> | <commit>
build: <the files the loop opened> | <the author's verdict and what was done with it> | <commit>
fork: <what the two shapes disagree about, in one line>
side A: <one line>
side B: <one line>
losing criterion: <the Ticket criterion one side would rewrite> | none
stopped at: <the behaviour line the loop stopped on>
```

The fork report is the whole of what the session rules on, since it forks the `choice-taker`
against a Spec this fork never read: both sides, which criterion would lose, and where the build
stopped. The fork rules on nothing itself and classes nothing as Design or Extreme, per
[forks.md](forks.md): the `choice-taker`'s own return already reads `settled` or `extreme`.

A stretch that stopped for any other reason:

```
stopped
behaviour: <the Plan's behaviour line, verbatim> | <commit>
build: <the files the loop opened> | <the author's verdict and what was done with it> | <commit>
stopped: <the reason, in one line>
```

The `stopped:` line is what both of the session's routes read: a reason it can clear (a seam that
is production code to change, a project map slot to fill, a spent window) is cleared and the
Builder forked again, and one it cannot ends the run as blocked with something to act on.

Those lines are the whole of what crosses back: never the diff, never the test output, never a
file's contents, and no branch or worktree line either, since the session named both in the brief
and reads the branch itself. Nothing downstream would catch a Builder that pasted its build back:
the run still builds, still gates and still lands, and only the window the fork exists to keep
empty is gone.

## What it builds from

The Plan the brief names, and the tree. Its `## Behaviours` list is taken one item at a time, in
its order, through the loop of [build-loop.md](build-loop.md): each item is already a test author's
dispatch input without its `Expected red` key, which the cycle that dispatches fills from the tree
as it stands at that cycle. Its `## Sketch` section is the shape the build is held to where the
shape step fired, and the shape the Plan states in one line where it did not.

Its `## Map` is the subsystem as it stood before the diff. It is read to find things, never handed
on: the review builds its own map after the diff, per [mechanics.md](mechanics.md).

The Ticket and the Digest are read for the criteria and the quotes the behaviours trace to. Neither
the Spec nor the journey is opened: the Digest is the slice, per [digest.md](digest.md).

## Where it picks up

At the first behaviour of the Plan's list that carries no commit on the branch. The branch is the
durable state and the only state: every commit the loop makes carries `Behaviour: <line>` on a line
of its own, so a Builder forked again reads what is done off the commits rather than off a
run-state file somebody has to keep in step with them.

## Its edges

- The Gate is the session's, run in the worktree after the last edit and before the first review
  call, per [mechanics.md](mechanics.md). The fork runs the project's single-file command per cycle
  and never the gate.
- The flows are the fork's, authored or extended after the feature exists, by the E2E author of
  [build-loop.md](build-loop.md), over the criteria the Digest's `## Observable criteria` names.
  The fork commits each one and reports it on a `flow:` line.
- The integration, the review, the verification, the close and the Reply are the session's, and the
  fork touches none of them: no rebase, no landing, no push, no Ticket write, no branch but the one
  the brief names.
- A Design fork is reported and never ruled on. The Ruling is written to the Spec in the main
  checkout, out of the fork's reach, and the fork's own `Agent` hook denies `choice-taker` so the
  layer cannot be crossed by accident.
- A return the session's check refuses, a `behaviour:` line with no commit, a pair
  `resume-state.sh` does not print, or uncommitted work under `built`, is dropped whole: the run
  picks the stretch up from what `resume-state.sh` printed, the Resume section's own path, and says
  so on a fallback line.
