# journey

## What it does

`journey` walks every path of a spec from the actor's seat: who arrives and how, what they see,
what they do, what the system answers, and what happens when it fails. It reads the spec the
[spec](spec.md) skill wrote, finds the sibling pages and flows in the app that already do what the
stories describe, drafts each path from that precedent as a step table, and puts to you only the
forks the precedent leaves open, one question at a time with a recommendation and the failure it
hunts. The walked paths are written into a journey beside the spec, and the spec's `Journey:` line
is pointed at it, which is where [tickets](tickets.md) picks it up.

It never asks a technical question, and it never asks what the app already answers. Data shape,
boundaries, seams and delivery order are decisions [discuss](discuss.md) and `spec` made, taken as
given; a delete confirmation, an empty state or a form layout the sibling page already has is
closed with a file and line and never put to you.

## When to reach for it

You invoke this by typing `/journey <spec>`, and the agent won't reach for it on its own.

| Ask | Use |
|---|---|
| the spec's verdict says `Journey: required` | `/journey <spec>`: a path, the feature slug, or an issue reference; `spec` prints this line when it closes |
| the verdict says `not needed` but you want the paths walked anyway | `/journey <spec>`; the verdict line is replaced either way |
| decide the data shape, the seams or the plan itself | [discuss](discuss.md) first, then `spec` |
| cut the tickets | [tickets](tickets.md), once the journey is written; it refuses a spec whose verdict is `required` with no journey |
| see a screen before you can decide | the interview marks that fork _runnable_ and forks [prototype](prototype.md) for it |

The spec is asked for when it is left out. Answers arrive in the language you opened the session
in; everything written into the project is in English, except the UI copy the journey quotes.

## Prerequisites

A spec in the format `spec` writes, with its sections and the `Journey:` line under its title; the
skill resolves a slug through `docs/agents/issue-tracker.md` when that file exists and reads
`.scratch/<slug>/spec.md` when it does not. It writes into the project: the journey
(`.scratch/<slug>/journey.md` beside a local spec, or `docs/journeys/<slug>.md` plus a comment on
the spec issue when the spec is on a tracker), the spec's `Journey:` line and, for a reversible
change, the spec's own sections, and `CONTEXT.md` for a term a label or a status resolves.
Everything is left uncommitted. A runnable fork needs the `prototype` agent linked, as
[prototype](prototype.md) describes, and adds that agent's throwaway files, listed in the closing
summary.

## Path, fork, lens

A **path** is one thing the actor sets out to do, end to end, read off the spec's user stories; it
is the unit of the tree, and later the unit `tickets` cuts. A path is walked in **steps**: what the
actor sees, what they do, what the system answers. The paths are ordered the way the actor meets
them, create before edit before delete, so each lands as one demoable slice.

Every path is drafted first, from the **precedent**: the sibling page or flow that already does
what the story describes. A step the precedent settles is a default, cited with its file and line.
A step it does not settle is a **fork**, and a fork is the only thing that becomes a question. Each
fork is put through a **lens**, a design principle read from the actor's seat, with the **tell**
that fails it:

| Group | Lenses |
|---|---|
| Actor | experience-first |
| Subtraction | subtract-before-you-add, laziness-protocol |
| Shape | model-the-domain, minimize-reader-load, boundary-discipline |
| Alternatives | exhaust-the-design-space, redesign-from-first-principles |
| Failure branches, when the stories create, edit or delete | make-operations-idempotent, seeded by a CRUD grid of operations by conditions |
| Delivery | prove-it-works |

The full text of each principle is in [`.agents/principles/`](../.agents/principles/README.md);
the skill carries the question and the tell inline, so it works on its own. A fork closes as
**decided** (you chose), **default** (a reversible detail, stated with its reason) or **deferred**
(parked, with the condition that reopens it). A **cut** is a step or control deliberately left out,
and the journey keeps the list.

A fork only a screen can settle, a step with no precedent anywhere in the app, is **runnable**: the
session forks the [prototype](prototype.md) agent with a brief and puts the question to you against
the artifact, and the journey records the answer in one line, never the prototype.

## What a path can change

A path sometimes proves the spec wrong. What happens depends on how hard the change is to undo:

| The change | What happens |
|---|---|
| reversible: a field the actor needs to see, a step order, a missing story, a message | the spec is edited in place and the change is listed in the journey under `## Spec changes applied` |
| hard to reverse, or touching an ADR: a new entity state, a schema change, an interaction an ADR forbids | the path stops and asks which side wins; when the spec loses, the branch goes under `## Reopen in discuss`, and `tickets` stops on that list until [discuss](discuss.md) settles it |

The skill writes no ADR and edits no code.

## Slots

- `do` is not authored yet. The chain ends at the tickets, and the one line in the `SKILL.md`
  that leans on it carries the marker `stand-in until /do exists`.

## Common questions

**The verdict says `not needed`. Can I still run it?**
Yes. The verdict is `spec`'s reading of the stories' structure, not a lock. The paths are walked
the same way and the verdict line is replaced with the journey's location, so `tickets` reads the
journey.

**It edited my spec. Why?**
A path proved a reversible detail wrong: a field the actor has to see, a message, a step order, a
story that was missing. The edit is in the spec's own section and listed under
`## Spec changes applied` in the journey. A change that is hard to undo is never applied: the path
stops, asks which side wins, and records a losing spec under `## Reopen in discuss`.

**Why did it not ask me about the delete confirmation?**
The sibling page already has one, and the draft cited it with a file and line. A question is spent
only on a fork the app does not settle; the rest is a default you can overturn in the answer to the
question that does reach you.

## It's working if

- Before the first question you see a precedent note with files and lines, the tree of paths, and
  the first path's step table with its defaults marked.
- Every question reaches you alone, with a recommended answer and the failure it hunts, and none
  of them is about data, modules or tests.
- A step the sibling page settles never reaches you as a question.
- The journey grows one path at a time during the session, and the spec's `Journey:` line points
  at it only when the session closes.
- A screen with no precedent reaches you as something to open, never as a request to describe a
  layout in words.
- The closing summary lists every path, what was cut, what changed in the spec, and ends with the
  exact next command.

## Where it fits

`journey` is a step in the chain: it runs after [spec](spec.md), when the spec's verdict requires
it, and before [tickets](tickets.md), which cuts one ticket per path it walked.

- [spec](spec.md), because its spec is the only input, and its closing line names this skill when
  the stories add a screen or walk more than one path or step.
- [tickets](tickets.md), because it reads the journey through the spec's `Journey:` line, cuts one
  ticket per path, and stops on a journey with branches to reopen.
- [discuss](discuss.md), because the skeleton is the same and the decisions it made are taken as
  given here; a branch the journey sends back goes to it.
- [prototype](prototype.md), because a runnable fork forks its agent.
- The principles under [`.agents/principles/`](../.agents/principles/README.md), because every
  lens is one of them read from the actor's seat.

The grouped list of every skill is in [the top-level README](../README.md).
