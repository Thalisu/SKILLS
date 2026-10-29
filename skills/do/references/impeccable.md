# The impeccable fork

Read by the session on one run alone, the run whose door prints `kind=front-end` with
`front_end=impeccable`: a Front-end ticket of a Spec reading `Front-end: impeccable`. The Door of
[ticket.md](ticket.md) sends that run here, and each of its readers then reads its own section: the
Door, the Plan step, the build step, the close and the Reply. A run whose door prints anything else
never opens it.

The fork that builds one Front-end ticket of a Spec reading `Front-end: impeccable`, in the worktree
the session cut.
It is the `do-impeccable` agent `do` ships in [do-impeccable.md](../agents/do-impeccable.md), forked
by the build step of [ticket.md](ticket.md) in the Builder's place and by nobody else, one layer
below the session. No Planner runs ahead of it and no Plan exists: the Ticket's acceptance criteria
are its work list.

This file is the session's: it fills the brief from it and routes the return by it. The fork never
opens it, and reads its standing rules in its own definition, but for which criteria get a flow and
who authors each, which it reads at the installed do skill, the way the Builder does. Read
[flows.md](flows.md) when the fork reaches the flows, after the screen's last criterion is
committed.

## The Door

A Front-end ticket of a Spec reading `Front-end: impeccable` (`kind=front-end` with
`front_end=impeccable`) that every other stop of the Door of [ticket.md](ticket.md) let through is
stopped when the session lists no impeccable skill: its own skill listing names neither `impeccable`
nor a skill under `impeccable:`. A skill installed on disk that this session did not load is not
listed. The stop comes before the claim and before any worktree, in one message naming the Ticket,
the Spec's line and the skill the session does not list. Nothing is written, nothing is claimed and
nothing is cut: the Ticket keeps the `status=` the door printed. The message carries
`Yours: direction:` with the two choices, per [reply.md](reply.md): install impeccable, reload the
coding tool and run `/do <ticket>` again, or change the Spec's line to `Front-end: builder` and run
it again. The run never falls back to the Builder on its own.

## The Plan step

One Ticket skips step 1 of [ticket.md](ticket.md) whole: a Front-end ticket of a Spec reading
`Front-end: impeccable`, the door's `kind=front-end` with `front_end=impeccable`.
It forks no Planner and writes no Plan, on a first run and on a resume alike, and the session does
not ground it in the Planner's place either. The step reads
`skip: an impeccable Front-end ticket forks no Planner` on the checklist, names no destination and
runs none of that step's checks, and the run goes on to step 2 with the Ticket's and the Digest's
hashes the door recorded. Every later passage that rewrites or checks the Plan's `## Sources` lines
has no file to act on for this Ticket and compares those two hashes alone. The Project map and the
context reading at the end of step 1 are still the session's to take. Every other Ticket keeps
that step as written: a Logic ticket, and a Front-end ticket under `Front-end: builder`, still fork
the Planner and build from its Plan.

## The build step

At step 3 of [ticket.md](ticket.md), a Front-end ticket of a Spec reading `Front-end: impeccable`,
the door's `kind=front-end` with `front_end=impeccable`, is built by another fork in the Builder's
place: call the Agent tool with `subagent_type: do-impeccable`, the agent `do` ships in
[do-impeccable.md](../agents/do-impeccable.md), from inside the worktree and the branch step 2
created, cut as for any Ticket. Its brief carries the Ticket, the worktree root, the loop line
and the Project map and nothing else, the four keys `## The brief` below fixes.

The brief of `do-impeccable` has no key for where the return goes: the return is the fork's final
message, as the Builder's is, and no return file is written anywhere. It carries no rule
either: what the fork loads, where it may write, how it commits and what it returns live in the
agent's definition. Everything step 3 does around the Builder's fork it does
around this one, the two revokes before it, the guard probe and the revoke as soon as it returns.
When the Agent tool is
withheld or lists no `do-impeccable`, the run stops as blocked in one line saying which of the two
holds, with the worktree and its branch named and `scripts/link-skills.sh` as the run that links
the agent before the next `/do`.

Around the fork of `do-impeccable`, and around that fork alone, the run reads the main checkout
twice by script. Before the fork,
`bash <skill-dir>/scripts/main-untouched.sh snapshot <the main checkout> <the state file>` records
the checkout's uncommitted state, with its git hooks and its git config. A file git ignores is outside what it reads. The state file is
`<the main checkout's git common dir>/do/main-state/<the slug>.state`, the path
`git -C <the main checkout> rev-parse --path-format=absolute --git-path do/main-state/<the slug>.state`
prints, under the slug step 2 cut the worktree with. It is written neither under
`.scratch/` nor in the Ticket's `issues/` folder.
After the fork returns, right after the revoke step 3 takes as soon as the fork returns and before
any check or route of the return,
`bash <skill-dir>/scripts/main-untouched.sh check <the main checkout> <the state file>` compares
the checkout with that record, so the check always runs before step 4 and before the Gate. Every fork gets a snapshot of its own: a re-fork after a `fork` or a
cleared `stopped`, and a resumed run that forks again, snapshots again first.

Either call exiting 2 prints no verdict, and no verdict is never an untouched checkout. A snapshot
that exits 2 stops the run as blocked before the fork, with nothing forked, the Ticket still
`claimed` and the worktree and its branch kept and named, in one line quoting the script's reason. A
check that exits 2 stops the run as blocked before any check or route of the return, the way
`verdict=changed` does below, the worktree, its branch and its commits kept for the resume and its
line quoting the script's reason. On `verdict=untouched` from `main-untouched.sh check` the run goes
on to the checks and the routes of the return with nothing added to the Run report. On
`verdict=changed` the run stops as blocked before the Gate, whatever verdict the fork returned. The
stop's class is `direction`: the Reply lists the `file=` lines the check printed, which are the
files that changed since the fork began and never the work that was already uncommitted, a git hook
or the git config among them as an absolute path, and carries one `Yours: direction:` line with the
two choices, to move the files into the worktree by hand and run `/do` on the Ticket again, or to
discard them and run `/do` again, in the blocked shape.
Read [blocked-reply.md](blocked-reply.md) when the run stops on a changed main checkout. The run removes
nothing, in the main checkout or anywhere else. The worktree and its commits stay in place for the resume, and the Ticket still
reads `claimed`.

The return of `do-impeccable` is the lines and the one terminal verdict a Builder returns, so
everything step 3 reads of a Builder's return is read with `do-impeccable` in the Builder's place
and nothing is added for it: the same checks of the return against the branch, the first line and
the `resume-state.sh` pairs, and the same three routes, `built`, `fork` and `stopped`. Its
`behaviour:` lines carry the Ticket's acceptance criteria where a Builder's carry the Plan's
behaviours, and a criterion it could not build comes back as `stopped` or `fork`, never under
`built`, and takes that route. With no Plan, the re-check before the route is the call with no
destination, `grounding.sh verify <root> <ticket=> <ticket_hash=> <digest=> <digest_hash=>`, routed
the same way. A re-fork after a `fork` or a cleared
`stopped` hands it the same four-key brief. A spent time budget is cleared for it as for a Builder:
the next Stretch is a new Agent call
with `subagent_type: do-impeccable` and that same brief, never a Builder or a Planner in its place,
and the run never ends as blocked over it.

Among the pairs `resume-state.sh` prints, step 3 passes over a pair reading `behaviour=<sha> none`
wherever it sits, as one of the commits that carry no `Behaviour:` line by contract, and needs no
returned line to match it. From `do-impeccable` those commits are a flow committed on its own, the
fix a `HANDBACK` diagnosed `production` and the fix of its detector scan.

When `do-impeccable` returned `built` and the check of the main checkout read `verdict=untouched`,
the run takes the same path from the routes of step 3 as after a Builder: the diff of step 4, the
Gate of step 5, the integration of step 6, the landing of step 7 and the close of step 9 run exactly
as they do after a Builder, with no step added, skipped or changed for this fork. The run ends as a
Builder's does: the Ticket reads `resolved`, and the Reply's last line is the next `/do`, the one
the Completion check's `next=` line names.

The fallback of step 3, the session running the loop when no Builder can be forked, never reaches a
Front-end ticket of a Spec reading `Front-end: impeccable`. The Door stopped it when the session
lists no impeccable skill, and the build step never falls back to the Builder for it on its own,
neither by forking `do-builder` nor by the session running the loop in its place.

## The close

At step 9 of [ticket.md](ticket.md), the close of a run that forked `do-impeccable` appends the
fork's `scan:` line (the detector scan's command line and the count of findings that remain) under
the Ticket's `## Evidence`, beside the flows' command lines, unchanged as the fork returned it.

## The Reply

The Reply [reply.md](reply.md) fixes reads differently in these parts on a run that forked
`do-impeccable`, on a Front-end ticket of a Spec reading `Front-end: impeccable`, and in no other:

- **Plan line.** The message's `Plan:` line reads `Plan: none, <reason>`, its reason a fork of
  `do-impeccable`, which builds from the Ticket's acceptance criteria. The Run section carries no
  Plan line at all. Its `Guard:` line still rides, on the fork of `do-impeccable`.
- **Behaviours list.** On a run that forked `do-impeccable`, the list is the Ticket's acceptance
  criteria, never a Plan's `## Behaviours` section, each criterion verbatim with the commit beside
  it, off the `behaviour:` lines the fork returned.
- **The proof of an impeccable screen**, under Evidence, on a run that forked `do-impeccable`: the
  `flow:` lines the fork returned and, beside the flows, its `scan:` line, which is the detector
  scan's command line and the count of findings that remain, all copied unchanged. When its return
  carried the `fallback:` line reading `no end-to-end command in the project` in place of the
  `flow:` lines, one line stands here instead of them, saying that no flow covered the screen and
  that the detector scan and the Gate are its proof. When its return carried the `no scan:` line in
  place of the `scan:` line, that line is copied unchanged, with its reason.
- **Pending debt.** Each `finding:` line the fork returned is listed under Pending debt, one line
  per finding. Findings that remain are debt
  and never a stop: the Ticket still lands and reads `resolved` all the same.

### A main checkout that changed

A `ticket` run that forked `do-impeccable` and found the main checkout changed during the fork is a
blocked run of [reply.md](reply.md), stopped before the Gate by the build step above. Its blocker is
followed by the files that changed since the fork began, one per line, each the value of a `file=`
line `main-untouched.sh check` printed, and never the work that was already uncommitted before the
fork, which the check leaves out. It says the run removed nothing, names the run's worktree and its
branch, both left in place with their commits, and says the Ticket still reads `claimed`:

```
The main checkout changed during the do-impeccable fork:
<file>
<file>
Yours: direction: move the files above into <worktree> by hand and run /do <ticket> again, or discard them and run /do <ticket> again
```

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

The keys are written here and in no second place. The brief has no key for where the return goes:
the return is the fork's final message, and nothing is written for it, in the worktree or outside
it. It carries no rule either: what the fork loads, where it may write, how it commits and what it
returns live in the definition.

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
- A `build:` line names `impeccable` where a Builder's names a test author's verdict.
- A criterion the fork could not build comes back as `stopped`, or as `fork` when two shapes
  disagree, and never under `built`.

The fork's Stretch runs on the Builder's time budget, per `## Asking the time budget` of
[builder.md](builder.md). It takes its start when its Stretch begins and asks
[stretch-budget.sh](../scripts/stretch-budget.sh) after each criterion's commit and at no other
moment: never inside a criterion, after a flow's commit or after the scan. On `stretch=stop` it
returns `stopped` in the Builder's shape, its `stopped:` line naming the spent time budget in the
Builder's own words and saying that nothing is uncommitted. Where a Builder's `stop` after its last
behaviour can already be `built`, this fork's never is: it returns `stopped`, and the next Stretch finds a commit beside every criterion and goes on
to them.

On `built`, one `flow:` line per criterion follows the pairs, in the shape [builder.md](builder.md)
fixes: the commit that carries the flow, or the reason no flow was written. The flows are the
fork's and never the session's. They are written after the screen exists, by the end-to-end author
under the Builder's own rule, over the criteria the Digest's `## Observable criteria` section names.
Read [flows.md](flows.md) when that section names a criterion, or no Digest sits beside the Ticket. The fork holds the Agent tool and dispatches that
author itself, the one its brief's `Loop:` key names, and a hook of its own keeps the tool to the
two end-to-end authors and the helper agents impeccable ships. The session copies the `flow:` lines
into the Run report's Evidence unchanged.

In a project with no end-to-end command the fork writes no flow, and one line comes back in place
of the `flow:` lines: `fallback: no end-to-end command in the project`. The session then writes one
line in the Run report's Evidence, saying that no flow covered the screen and that the detector scan and
the Gate are its proof.

After those lines comes one `scan:` line, the command line of impeccable's detector scan as it was
run and the count of findings that remain, then one `finding:` line per finding left. The scan is
the fork's to run, by script, after the flows, and the fork fixes what it reports before it
returns: the session never runs the detector. Findings that remain come back under `built` and do
not stop the run, so the Ticket still lands. The session copies the `scan:` line into the Run report's
Evidence, beside the flows, and each `finding:` line into its Pending debt.

Where the loaded impeccable skill names no detector for the project's platform, as with a native
project, or the detector crashed, the fork returns one `no scan:` line in place of the `scan:` line,
with its reason and no `finding:` line, still under `built`. The session copies the `no scan:` line
into the Run report's Evidence.

The definition carries this shape itself: a change to the lines the Builder returns is made in
[do-impeccable.md](../agents/do-impeccable.md) in the same change.
