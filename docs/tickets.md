# tickets

## What it does

`tickets` cuts a spec into tracer-bullet tickets: vertical slices, each a narrow but complete path
through every layer, demoable on its own, declaring the tickets that block it. When the spec's
verdict points at a journey, every walked path becomes one slice, its steps and failure branches
become the acceptance criteria, and the states the actor sees set the order. The breakdown is put
to you as a numbered list, and once you approve it the tickets are published one file per ticket
locally, or one issue per ticket on the project's tracker with native blocking links.

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

The skill writes into the project: one file per ticket under `.scratch/<feature-slug>/issues/`
when the tracker is local markdown, or one issue per ticket on the tracker that
`docs/agents/issue-tracker.md` describes. Without that file the tickets land beside the spec as
local markdown, and no setup skill is demanded; an issue reference still needs the file to resolve.

## Path, slice, stop

A **slice** is the unit: a tracer bullet through schema, API, UI and tests that a reviewer can demo
when it lands, sized for one fresh context window. Every slice names its **blocking edges**, and
the **frontier** is every slice whose blockers are done: the tickets an agent can grab right now.

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

One neighbour of this skill is not in this repo yet.

| Slot | Today |
|---|---|
| `do` | none; the chain ends at the tickets. The one line in the `SKILL.md` that leans on it carries the marker `stand-in until /do exists` |

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

## It's working if

- With a journey, the breakdown names the path each ticket realises, and each ticket reads as one
  thing the actor can do end to end, never as one layer of every path.
- The first ticket has no blockers, and every other ticket's blockers are tickets that genuinely
  gate it: a restore path is blocked by the archive path that creates the state it needs.
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
