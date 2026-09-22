# The Plan

The grounding a `do` ticket run builds from, read out of the Ticket, its Digest and the tree by the
Planner the Plan step of [ticket.md](ticket.md) forks, and written by that fork itself, per
[ADR 0047](../../../docs/adr/0047-the-ticket-run-forks-a-planner-then-a-builder-and-the-session-stops-writing-code.md).
The session holds the Plan's path and never its text: the grounding is what a run pays for over and
over, and a session that carries everything read to write it compacts before the build is done. The
Plan is written once and read many times, by the loop that builds from it and by the next run on the
same Ticket, which reads it instead of grounding again.

## The brief

The fork is the `do-planner` agent `do` ships, and it is dispatched with these and nothing else,
since it opens what it needs itself:

```
Ticket: <the absolute path in the main checkout, or the tracker reference>
Criteria: <the Ticket's checklist, verbatim>
Digest: <the absolute path in the main checkout> | none
Sources: <the `## Sources` lines the door computed, to be copied whole and never recomputed>
Rulings: <the `Ruled by the choice-taker on Ticket <this Ticket>` lines the door read off the Spec, or none>
Plan: <the absolute path this Plan is written at>
Repository root: <the main checkout's absolute path>
Tree: <the worktree the build runs in, or the repository root>
Flow: ticket | bug-fix | refactoring
Agents folder: <the absolute path of the chain's `.agents/` folder>
```

The brief names one path to write and no hash to compute. The fork holds `Write` for that one path,
and holds no tool that runs a command: the session checks the Plan's `## Sources` lines against the
hashes the door computed before the fork, per
[ADR 0048](../../../docs/adr/0048-a-fork-writes-its-own-artifact-and-the-session-verifies-the-header-it-computed.md),
and a fork that could compute a hash of its own would be vouching for its own grounding.

It returns the Plan's path, and one line for each thing that fell back. It returns none of the
Plan's text.

## What it holds

Six sections, in this order.

- `## Sources`: what the Plan was cut from, one line per document,
  `<name>: <absolute path> <hash>`, with `ticket` and `digest` as the two names and the hash from
  the `git hash-object` the door runs in the main checkout before it forks. The fork copies these
  lines from its brief whole and writes no line of its own there. A document that is not on disk is
  recorded `<name>: absent` instead. The session compares the two values it computed against the two
  the file carries, so it learns the Plan is the one it asked for without reading a word of it.
- `## Grounding`: the glossary words `CONTEXT.md` gives the work, one line each with the type or
  record each maps to; the titles of the ADRs the fork opened, one per line, and nothing of their
  bodies; and the discover audit line, `Discovery: n FOUND · n DUPLICATE · n NOT_FOUND`, with the
  line saying so when one `rg -n -w` per candidate stood in for the batch. It is what the fork read,
  not what it read it in: no file is quoted here.
- `## Predicate`: done as a predicate, each part checkable, sharpened by what the reading showed.
- `## Map`: the subsystem as it stood before the diff, where things live, what calls what and where
  the seams are. Its first line says that it is the pre-diff subsystem and that it is never handed
  to the review, since each reviewer builds its own map after the diff and a map of the tree as it
  was would read the work under review as code that was already there.
- `## Behaviours`: the numbered list the build loop takes one item at a time, cut from the Ticket's
  criteria and its `What to build` line and from the Digest's quotes, never from the implementation.
  Each item is a test author's dispatch input without its `Expected red` key: the behaviour to
  prove, who relies on it and what a wrong or missing result costs them, the target, and the origin.
  The expected red depends on the tree at the cycle that dispatches, so the loop fills it. A line
  that reproduces a defect is marked `bugfix`. A line no quote in the Digest carries is one the fork
  invented. A criterion that still reads the side a `Rulings:` line the developer edited reversed
  is not built either way: it is a Design fork between that criterion and the edited line, and the
  item says so with both sides, for the session to rule on.
- `## Sketch`: the text the `sketch` fork returned, whole, its own header included and its
  `Written:` key reading this Plan's path, since this is the file the Sketch landed in, and every
  heading in it demoted two levels: its title reads `### Sketch: <what it shapes>` and its own
  sections read `#### The caller's usage` and the rest. No line of it opens a level-2 heading, which
  is what keeps the whole Sketch inside this one section: the build is held to this section, and a
  Sketch whose usage, types, signatures, boundaries and rejected rivals fell outside it would hold
  the build to the Sketch's header keys alone. Or `none`
  on one line with the reason beside it: no boundary crossed, `sketch` not listed, the Agent tool
  withheld, or a return that is not a usable Sketch.

## Where it lives

In the main checkout's scratch, beside the Ticket file, taking the Ticket's file name with `.plan`
before the extension: `02-export-notes.plan.md` beside `02-export-notes.md`. The Ticket's slug is
the key, the Digest's own rule, so two runs on two Tickets of the same feature never reach for the
same file. A Ticket that is not a local file has no file to sit beside: it keys the Plan by the
issue's reference under `.scratch/plans/` in the main checkout, carrying that same `.plan` before
the extension, `.scratch/plans/42.plan.md` for issue 42. The suffix is the whole of what the
Planner's own `PreToolUse` hook matches a write against, so an issue-keyed path that stops at `.md`
is a Plan the fork is refused and the run has nothing to build from.

The path is the main checkout's absolute one, since a run inside a worktree has no scratch of its
own, per [scratch.md](../../../.agents/scratch.md). The door's `find` counts a `.plan.md` out when
it resolves a blocker's number, the way it already counts a `.digest.md` and a `.sketch.md` out, so
a Plan left beside a Ticket that is gone never supplies a blocker's status.

## Its edges

A Plan already at that path whose `## Sources` section is exactly the two records the door just
computed, matched on name, path and hash together, is carried: the run forks nobody and builds from
the Plan it already has. A Plan whose section is not that exact match is a Plan cut from a Ticket or
a Digest that has since moved, or one whose records were tampered with, and the run forks the
Planner again, replacing it whole.

A Plan is replaced whole and never edited. The fork that writes it holds one path, so there is no
second writer to merge with, and a run that needs a different Plan gets a new one rather than a
patched one.
