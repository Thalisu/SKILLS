# tickets

## What it does

`tickets` cuts a spec into tracer-bullet tickets: vertical slices, each a narrow but complete path
through every layer, demoable on its own, declaring the tickets that block it. When the spec's
verdict points at a journey, every walked path becomes one slice, its steps and failure branches
become the acceptance criteria, and the states the actor sees set the order. The skill decides the
cut and never asks about it: every ticket carries an estimate of the context the `do` session will
reach on it, a ticket waits for the ticket that writes what it reads, a small ticket on a single
edge is folded into its neighbour, a large one is split along its steps, and the breakdown shows the
reasoning behind each. The one question you get is whether the breakdown goes out; once you say yes
the tickets are published one file per ticket locally, or one issue per ticket on the project's
tracker with native blocking links.

It publishes nothing when its input is broken. A verdict that requires a journey nobody walked, a
verdict pointing at a file that is not there, a journey that lists branches to reopen in discuss,
or tickets that already exist for the feature each stop the run with one message and nothing
written; the way past is to fix the input and run again.

## When to reach for it

You invoke this by typing `/tickets <spec>`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| cut a spec, and the journey its verdict points at, into tickets | `/tickets <spec>`: a path, the feature slug, or an issue reference |
| write the spec first, from a decided conversation | [spec](spec.md); its closing line names this skill when no journey is needed |
| walk the user journey first, when the verdict says `required` | [journey](journey.md), `/journey <spec>`, typed by you |
| decide the plan, or settle a branch the journey sent back | [discuss](discuss.md) |
| build one ticket | the chain ends here until `/do` exists (see Slots) |

The spec is the only input: the conversation is never cut directly, and a missing spec is asked
for. Answers arrive in the language you opened the session in; everything written into the
repository or the tracker is in English.

## Prerequisites

The skill writes into the project: one file per ticket under `issues/` in the spec's own feature
folder, `.scratch/<YYYYMMDD>-<feature-slug>/issues/`, when the tracker is local markdown, or one
issue per ticket on the tracker that `docs/agents/issue-tracker.md` describes. Without that file
the tickets land beside the spec as local markdown, and no setup skill is demanded; an issue
reference still needs the file to resolve. A project missing the `.scratch/` line in its
`.gitignore` gets it before the first local write, since the scratch folder is never versioned.

## Path, slice, stop

A **slice** is the unit: a tracer bullet through schema, API, UI and tests that a reviewer can demo
when it lands. Every slice names its **blocking edges**, and the **frontier** is every slice whose
blockers are done: the tickets an agent can grab right now. An edge is never a guess: a slice that
reads what another writes (a state, a section, a symbol) is blocked by the one that writes it, and
a stub to let it start sooner is never cut.

Every slice carries an **estimate**, the peak context the `do` session is expected to reach while
building it, never the total its forked agents spend, with the criteria count and the modules
crossed that drive the number, so you can check it. The estimate puts the slice in a **band**, and
the band decides what the skill does with it:

| Band | Peak context | What happens |
|---|---|---|
| small | under 150k | folds into the ticket at the other end of its single edge when the fold delays no ticket's start and the merged estimate stays medium at most |
| medium | up to 200k | published as cut |
| large | beyond 200k | split along its steps, every piece demoable; never published |

The estimate is calibrated, not only guessed. On every ticket it resolves, `do` reads the session's
context from the harness transcript twice, at the end of grounding and at the close, where the peak
is read, and writes both into the ticket's evidence as a `Context:` line. `tickets` reads those
lines from the resolved tickets in the repo to set the fixed load and the per-criterion cost of the
next cut. A repo with no measured ticket is cut on stated defaults, and every estimate in that
breakdown says so.

Where the slices come from is decided by the spec's **verdict**, the `Journey:` line under its
title:

| The verdict | The cut |
|---|---|
| a location, once the journey is written | one **path** of the journey is one slice; the path's outcome is what to build, its step table and failure branches are the acceptance criteria, its `## States` draws the edges, its cut and deferred items are left out and listed |
| `not needed, <condition>` | the User Stories are the paths, cut by the same rules, and the run says so in one line |
| no line at all | the spec did not come from `spec`; the stories are the paths, and the run says so |
| `required` | a stop: the journey comes first |

Four inputs **stop** the run before anything is explored or written:

| Condition | What you read |
|---|---|
| the verdict is `required` and names no journey | the verdict, and that `/journey` walks the spec first |
| the verdict names a file that is not there | the line and the location it named |
| the journey's `## Reopen in discuss` lists a branch | each branch, and that `/discuss` settles them before the journey is walked again |
| tickets for the feature already exist | each one; close or delete them first for a recut |

A wide refactor, one mechanical change whose blast radius spans the codebase, is the one exception
to vertical slicing: it is sequenced as expand, migrate in batches, contract, each batch its own
ticket.

## Slots

None. `do` is in this repo, so the close ends on the exact next command, `/do <ticket>`, with
the first ticket of the frontier.

## Common questions

**It stopped and wrote nothing. Why?**
One of the four stops fired, and the message names which: a verdict that requires a journey nobody
walked, a verdict pointing at a missing file, a journey with branches to reopen in discuss, or
tickets already published for the feature. There is no flag to push past it. Fix the input (walk
or move the journey, settle the branches, close the old tickets) and run again.

**Can I pass the journey as a second argument?**
No. The spec's verdict says whether there is a journey and where it is, and that line is the only
lookup. A journey beside the spec that the verdict does not name is reported as an orphan, not
read.

**It used to ask whether the edges held and whether tickets should be merged. Where did that go?**
Into the breakdown. Both were answers the skill could read off the cut, and each round trip stalled
the chain on you. An edge now comes with what the ticket reads and who writes it, and a fold or a
split comes with the rule that fired. Overrule any of it in your reply; the breakdown is redrawn and
put to you again with the same one question.

**Every estimate says uncalibrated. What do I do?**
Nothing in the cut. Build one ticket with `do`; its close writes the measured context into the
ticket's evidence, and the next `/tickets` run in the repo calibrates from it. Until then the
numbers are the defaults, which is why the breakdown says so beside each one.

**Two of my paths came back as one ticket. Why?**
Both were small and tied by a single edge, so the later folded into the earlier, and the ticket
names both paths. In a small codebase that fires often, since nearly every path is small. Say so in
your reply if you want them apart; the fold is a default, not a stop.

## It's working if

- With a journey, the breakdown names the path each ticket realises, and each ticket reads as one
  thing the actor can do end to end, never as one layer of every path.
- The first ticket has no blockers, and every other ticket's blockers are the tickets that write
  what it reads: a restore path is blocked by the archive path that creates the state it needs,
  never by an earlier ticket and never with a stub.
- Every ticket in the breakdown carries an estimate and its band, a fold or a split names the rule
  that fired, and the only question you get is whether the breakdown goes out.
- What the journey cut or deferred shows up under what was left out, never as a ticket.
- Nothing lands in `.scratch/` or on the tracker before you approve the breakdown, and nothing at
  all on a stop.
- The parent spec is untouched and the working tree is uncommitted after the run.

## Where it fits

`tickets` is a step in a strict chain: after [spec](spec.md), and after the journey when the spec's
verdict requires one, and before each ticket is built. It replaces `/mattpocock-skills:to-tickets`
at that step.

- [spec](spec.md), because its verdict decides whether a journey comes first, and its closing line
  names this skill when none is needed.
- [discuss](discuss.md), because a journey's reopened branches go back to it.
- [journey](journey.md), because its paths are the slices this skill cuts, and its
  `## Reopen in discuss` is one of the stops.

The grouped list of every skill is in [the top-level README](../README.md).
