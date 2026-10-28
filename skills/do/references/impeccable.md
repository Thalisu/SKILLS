# The impeccable fork

The fork that builds one Front-end ticket of a Spec reading `Front-end: impeccable`, in the worktree
the session cut, per
[ADR 0078](../../../docs/adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md).
It is the `do-impeccable` agent `do` ships in [do-impeccable.md](../agents/do-impeccable.md), forked
by the build step of [ticket.md](ticket.md) in the Builder's place and by nobody else, one layer
below the session. No Planner runs ahead of it and no Plan exists: the Ticket's acceptance criteria
are its work list.

This file is the session's: it fills the brief from it and routes the return by it. The fork never
opens it, and reads its standing rules in its own definition, but for which criteria get a flow and
who authors each, which it reads in `## The flows` of [builder.md](builder.md) at the installed do
skill, the way the Builder does.

## The Door

A Front-end ticket of a Spec reading `Front-end: impeccable` (`kind=front-end` with
`front_end=impeccable`) that every other stop of the Door of [ticket.md](ticket.md) let through is
stopped when the session lists no impeccable skill: its own skill listing names neither
`impeccable` nor a skill under `impeccable:`. The script cannot print this fact, since the listing
is the session's and never a file's: a skill installed on disk that this session did not load is
not listed, and impeccable could not run in it. The stop comes before the claim and before any
worktree, in one message naming the Ticket, the Spec's line and the skill the session does not
list. Nothing is written, nothing is claimed and nothing is cut: the Ticket keeps the `status=` the
door printed. Who builds the screen is the developer's call, so the message carries
`Yours: direction:` with the two choices, per [reply.md](reply.md): install impeccable, reload the
coding tool and run `/do <ticket>` again, or change the Spec's line to `Front-end: builder` and run
it again. The run never falls back to the Builder on its own: the Spec's line is the developer's
choice of who builds the screen, and a screen built by `do-builder` under `Front-end: impeccable`
is one nobody chose.

## The Plan step

One Ticket skips step 1 of [ticket.md](ticket.md) whole: a Front-end ticket of a Spec reading
`Front-end: impeccable`, the door's `kind=front-end` with `front_end=impeccable`, per
[ADR 0078](../../../docs/adr/0078-an-impeccable-front-end-ticket-forks-no-planner-and-do-impeccable-stands-in-for-the-builder.md).
It forks no Planner and writes no Plan, on a first run and on a resume alike, and the session does
not ground it in the Planner's place either: impeccable builds from the Ticket's acceptance
criteria and reads no Plan, so a Plan here is a fork paid for and never opened. The step reads
`skip: an impeccable Front-end ticket forks no Planner` on the checklist, names no destination and
runs none of that step's checks, and the run goes on to step 2 with the Ticket's and the Digest's
hashes the door recorded. Every later passage that rewrites or checks the Plan's `## Sources` lines
has no file to act on for this Ticket and compares those two hashes alone. The Project map and the
context reading at the end of step 1 are still the session's to take. Every other Ticket keeps
that step as written: a Logic ticket, and a Front-end ticket under `Front-end: builder`, still fork
the Planner and build from its Plan.

## The brief

The fork is dispatched with these four keys and nothing else:

```
Ticket: <the absolute path in the Home repository>
Worktree: <the absolute path of the worktree root the build runs in>
Loop: policy | global | fallback
Project map: <the absolute path `project-map.sh` printed> | none
```

`Loop:` and `Project map:` are the Builder's own two keys, filled the same way: the loop line step 0
of [ticket.md](ticket.md) recorded, and the map its Plan step derived, which that step still takes
for this Ticket. The fork reads them to pick the author of each flow.

The keys are written here and in no second place, the rule [builder.md](builder.md) holds for the
Builder's own. The brief has no key for where the return goes: the return is the fork's final
message, so nothing is written for it, in the worktree or outside it. It carries no rule either.
What the fork loads, where it may write, how it commits and what it returns are the same on every
run, so they live in the definition, where a brief composed on one run cannot drop one of them.

The brief is the same on the first fork and on every re-fork. Nothing in it says where to pick up:
a fork dispatched again reads the `Behaviour:` lines off the branch and carries on from the first
criterion that has none. The Stretch forked after a spent time budget is no exception: the session
clears that `stopped` return by forking `do-impeccable` again at once, per the `stopped` route of
the build step of [ticket.md](ticket.md), with no key added and no file written between the two.

## The return

The fork's final message, in the lines and the one terminal verdict [builder.md](builder.md) fixes
under `## The return`: `built`, `fork` or `stopped` alone on the first line, then one `behaviour:`
and one `build:` line per criterion the stretch closed. The session checks it and routes it as it
does a Builder's, per the build step of [ticket.md](ticket.md). Three things read differently:

- A `behaviour:` line carries a criterion of the Ticket, verbatim, where a Builder's carries a
  behaviour of the Plan. It is the sentence the commit carries after `Behaviour:`, so the pairs
  `resume-state.sh` prints match it the same way.
- A `build:` line names `impeccable` where a Builder's names a test author's verdict, since no test
  is written ahead of the screen.
- A criterion the fork could not build comes back as `stopped`, or as `fork` when two shapes
  disagree, and never under `built`.

The fork's Stretch runs on the Builder's time budget, per `## The time budget` of
[builder.md](builder.md). It takes its start when its Stretch begins and asks
[stretch-budget.sh](../scripts/stretch-budget.sh) after each criterion's commit and at no other
moment: never inside a criterion, after a flow's commit or after the scan. On `stretch=stop` it
returns `stopped` in the Builder's shape, its `stopped:` line naming the spent time budget in the
Builder's own words and saying that nothing is uncommitted. Where a Builder's `stop` after its last
behaviour can already be `built`, this fork's never is, since the flows and the scan are still
ahead: it returns `stopped`, and the next Stretch finds a commit beside every criterion and goes on
to them.

On `built`, one `flow:` line per criterion follows the pairs, in the shape [builder.md](builder.md)
fixes: the commit that carries the flow, or the reason no flow was written. The flows are the
fork's and never the session's. They are written after the screen exists, by the end-to-end author
under the Builder's own rule, `## The flows` of [builder.md](builder.md), over the criteria the
Digest's `## Observable criteria` section names. The fork holds the Agent tool and dispatches that
author itself, the one its brief's `Loop:` key names, and a hook of its own keeps the tool to the
two end-to-end authors and the helper agents impeccable ships. The session copies the `flow:` lines
into the Run report's Evidence unchanged, per [reply.md](reply.md).

In a project with no end-to-end command the fork writes no flow, and one line comes back in place
of the `flow:` lines: `fallback: no end-to-end command in the project`. The session then writes one
line in the Run report's Evidence, saying that no flow covered the screen and that the detector scan and
the Gate are its proof.

After those lines comes one `scan:` line, the command line of impeccable's detector scan as it was
run and the count of findings that remain, then one `finding:` line per finding left. The scan is
the fork's to run, by script, after the flows, and the fork fixes what it reports before it
returns: the session never runs the detector. Findings that remain come back under `built` and do
not stop the run, so the Ticket still lands. The session copies the `scan:` line into the Run report's
Evidence, beside the flows, and each `finding:` line into its Pending debt, per
[reply.md](reply.md).

Where the loaded impeccable skill names no detector for the project's platform, as with a native
project, or the detector crashed, the fork returns one `no scan:` line in place of the `scan:` line,
with its reason and no `finding:` line, still under `built`. The session copies the `no scan:` line
into the Run report's Evidence, per [reply.md](reply.md).

The definition carries this shape itself, since the fork never opens this file and reads
[builder.md](builder.md) for its flows alone: a change to the lines the Builder returns is made in
[do-impeccable.md](../agents/do-impeccable.md) in the same change.
