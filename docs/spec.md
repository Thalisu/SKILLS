# spec

## What it does

`spec` turns the conversation you are in into a spec: the problem, the solution, an extensive list
of user stories, the implementation and testing decisions, and what is out of scope. It publishes
the spec where the project's issue tracker file points (a markdown file under `.scratch/`, or an
issue) and closes by naming the exact next command. It never interviews you: the decisions come from
the conversation, normally the closing summary of a [discuss](discuss.md) session, and the one thing
it checks with you is the seams the tests will drive the feature through, skipped when the summary
already names them.

The spec it writes carries a verdict. By reading the structure of its own user stories, `spec`
decides whether the feature needs a journey before tickets are cut, and writes that decision under
the title as a `Journey:` line, where the next skills read it.

## When to reach for it

You invoke this by typing `/spec`, and the agent won't reach for it on its own.

| Situation | Use |
|---|---|
| a `discuss` session just closed and its summary is in the thread | `/spec` |
| the summary lives in another session | `/spec` with the summary pasted after it |
| a `discuss --auto` session closed on `/spec --auto`, or you want the seams settled without you | `/spec --auto` |
| the plan is not decided yet | [discuss](discuss.md) first; `spec` sends you there when it finds no decisions |
| you have a spec and want every screen walked from the actor's seat | [journey](journey.md), `/journey <spec>`; `spec` names it when the verdict requires it |
| you have a spec and want tickets | [tickets](tickets.md), `/tickets <spec>`; `spec` names it when no journey is needed |

## Prerequisites

The skill writes into the project: `.scratch/<YYYYMMDD>-<feature-slug>/spec.md` when
`docs/agents/issue-tracker.md` says local markdown or does not exist, or an issue when that file
names GitHub or GitLab. The tracker file is the one the mattpocock plugin's setup skill writes;
`spec` reads it when it is there and needs nothing else in place. The spec is left uncommitted. The
scratch folder is never versioned, so a project missing the `.scratch/` line in its `.gitignore`
gets it before the write, and the closing summary says so along with where a spec the team has to
read belongs instead.

## The verdict

A **path** is one thing the actor sets out to do, end to end, walked in steps: arrive, see, act,
the system answers, or it fails. `spec` counts the paths and steps in the user stories it just
wrote, and the first matching row is the verdict:

| The stories | Verdict | Last line of the summary |
|---|---|---|
| need a screen or route that does not exist | `Journey: required` | `/journey <spec>` |
| let the actor do more than one thing (more than one path) | `Journey: required` | `/journey <spec>` |
| walk a path of more than one step | `Journey: required` | `/journey <spec>` |
| are each one interaction on an existing screen, or have no screen at all | `Journey: not needed, <condition>` | `/tickets <spec>` |

The rule reads structure and never size, so two runs on the same spec route the same way. The
chain is strict from here: `tickets` refuses a spec that says `required` and has no journey beside
it, and `do` builds one ticket, so `spec` never names it.

## Under `--auto`

`/spec --auto` hands the seams check over for one run. The token can sit anywhere in the arguments:
it is dropped, and the rest is read as it would be without it.

- Seams the conversation already names are taken as decided, exactly as without the flag. Nothing
  is ruled.
- Otherwise the seam set `spec` sketched and the set it rejected while sketching both go to the
  `choice-taker` agent, which picks one. You are asked nothing, and the spec is written.
- The spec's Testing Decisions say of each seam whether you confirmed it, the conversation gave it,
  or it was ruled. A ruled seam stands on a line of its own,
  `Ruled by the choice-taker under --auto: <the seam>. Norm: <the norm>.`, so you can find every
  seam nobody confirmed.
- The last line of the summary carries the flag, `/journey --auto <spec>` or
  `/tickets --auto <spec>`, so pasting it keeps the mode at the next skill.

The seams check still comes back to you, as the one question, with a line saying why, in two
situations. One is when no ruling can be had: the `choice-taker` is not linked, the Agent tool is
withheld, or what the agent returned is not a ruling on one of the sets it was handed. The other is
when the agent answers `extreme`, because a seam set would weaken a guarantee in a risk class
(security, data loss, billing and the like) or cannot be undone. The question then names the weaker
set and the guarantee it gives up. Either way no spec is written before you answer.

## Slots

- `do` is not authored yet, and `spec` never names it either way.

## The feature folder

A local spec gets a folder of its own, dated with the day it was written:
`.scratch/20260909-nightly-purge/spec.md`. Its journey and its `issues/` land beside it, so a
scratch that has collected a dozen features reads as a list of what you worked on and when. The
folder is allocated by a script, not composed by the agent, and the date never changes: a rerun
weeks later rewrites the spec in the folder the feature already has. Folders from before this rule
keep their undated names, and `/journey nightly-purge` or `/tickets nightly-purge` finds either
shape from the slug alone.

## Common questions

**It sent me to `/discuss` instead of writing anything. Why?**
The conversation held no decided plan. `spec` synthesises; it never asks you the questions a
`discuss` session would. Run `/discuss` on the plan and type `/spec` when the summary lands.

**I ran `/spec --auto` and it asked me about the seams anyway. Why?**
The line above the question says which case it was: the `choice-taker` could not be forked, its
return was not a ruling, or it returned `extreme`. A missing agent never turns into another agent,
or the session itself, ruling in its place. Answer the question and the run carries on, and its
last line still carries `--auto`.

**A feature that is only one new page got `Journey: required`. Is that too much?**
A new route is the first row of the verdict, and a page the actor does several things on is
several paths. The journey that follows drafts each path from the app's precedent and asks only
about the forks the precedent does not settle, so a small page closes fast.

## It's working if

- The only thing it asks is whether the seams match, and it does not ask even that when the
  summary already names them.
- Under `--auto` it asks nothing when a ruling can be had, and every seam in the spec's Testing
  Decisions reads confirmed, taken or ruled.
- The spec appears at the path the closing summary prints, with a `Journey:` line under its title.
- A local spec's folder carries the day it was written, and a rerun lands in that same folder
  instead of opening a second one.
- The last line of the summary is a command you can run as it is.
- Nothing else in the tree changed, and nothing was committed.

## Where it fits

`spec` is a step in the chain: it runs after [discuss](discuss.md) and before [journey](journey.md) or
[tickets](tickets.md), and the spec it writes is what the next step reads.

- [discuss](discuss.md), because its closing summary is the input, and it ends by naming `spec`.
- [tickets](tickets.md), because the verdict names it when no journey is needed, and it refuses a
  spec whose verdict is `required` with no journey beside it.
- [journey](journey.md), because the verdict names it first when a screen or a multi-step path is involved.

The grouped list of every skill is in [the top-level README](../README.md).
