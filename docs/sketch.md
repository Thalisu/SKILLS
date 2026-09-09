# sketch

## What it does

`sketch` settles the shape a piece of work has to hold before any logic is written, and files it.
It runs in a window of its own, explores rival shapes there, keeps the one that survives, and comes
back with two things: where it wrote the Sketch, and the shape in one line.

It always writes a file and it never writes code. That is the constraint the whole skill is built
around: a shape agreed in a thread dies with the window it was said in, and the run that has to be
held to it usually comes later, so the Sketch is a file on disk before it is an answer. The bodies
in it read `not implemented` by rule, which is what keeps the skill from quietly becoming the
implementation.

## When to reach for it

You invoke this by typing `/sketch`, and the agent will not reach for it on its own. That is the
only door open today: the skill also ships an agent, which a step of another skill may fork once
that step exists and the agent's description names it.

Reach for it when the work crosses a boundary somebody else will call, and you want the caller's
usage, the types, the signatures and the module boundaries settled before the first line of it
exists.

| What you want | Where to go |
|---|---|
| the shape of something other code will call, settled and written down | here |
| something runnable you have to click through or drive | [prototype](prototype.md) |
| the shape settled as part of building a Ticket | [do](do.md), which settles it at its own shape step |
| to understand a subsystem that already exists | `how` for the mechanism, `why` for the rationale |

## Prerequisites

The skill forks the `sketch` agent, so `skills/sketch/AGENT.md` has to be linked at
`~/.claude/agents/sketch.md` beside the skill link; see [the top-level README](../README.md).

It writes into the project's `.scratch/`, and it appends the `.scratch/` line to the project's
`.gitignore` first when that line is not already there, telling you it did.

## The Sketch, and the rivals that lost

The artifact is a **Sketch**: the caller's usage first, then the types, then the signatures with
unimplemented bodies, then which module owns what. The caller's usage comes first on purpose, since
a type nothing in the usage reaches for is a type nobody asked for.

The section that earns the skill its keep is the last one. Every candidate the exploration killed
is a **rejected rival**, written in one line: the shape in a few words, then the one fact that
killed it. A rival with no fact beside it was not explored, it was imagined, and the format says so.
Reading that list six weeks later is how you find out whether a shape was chosen or merely
defaulted into.

The exploration itself never enters your session. That is the point of the fork: you pay for the
Sketch, not for the reading behind it.

## Common questions

**How is this different from `prototype`?**
A prototype is runnable and throwaway, and you settle the question by driving it. A Sketch is not
runnable and not throwaway: it is the contract the build is then held to. Reach for the prototype
when you have to see it, and for the Sketch when you have to name it.

**There is already a vendored design skill. Why a second one?**
The vendored one runs its exploration through a skill this repository does not carry, so its
sketching phase cannot actually run here. `sketch` explores the rivals in its own window instead,
with the red-flag screen written into the agent, which is what makes it self-contained.

**Why does it write a file when I only asked a question?**
Because the answer outlives the conversation. A shape stated in a thread is gone after a compaction
and cannot be handed to a run tomorrow. Typed on its own, it files the Sketch under the feature slug
you pass, or one derived from your argument, and tells you the path.

**Can another skill call it?**
Not through the Skill tool: it is user-invoked, so only a person types it. The agent the skill
ships is a separate door, and the agent's own description names who may knock. Nothing knocks yet.

## It's working if

- Every run ends with a path, and there is a file at that path.
- Your context barely moves while it runs. The reading happened somewhere else.
- Each rejected rival carries the fact that killed it, not just a name.
- Nothing in the tree changed except the Sketch, and the `.gitignore` line when it told you it
  appended one.
- Every body in the file still reads `not implemented`.

## Where it fits

A standalone you type, and an agent a step can fire. You type it when the work crosses a boundary
and nothing in hand already carries a shape, whether or not a run is open. The agent is the second
door, and no step in the chain forks it yet.

Its neighbours are [prototype](prototype.md), because the two split on whether the question is seen
or named, and [do](do.md), because that is where a Sketch is usually spent. The grouped list of
every skill is in [the top-level README](../README.md).
