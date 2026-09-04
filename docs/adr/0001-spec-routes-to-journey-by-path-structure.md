# Spec routes to journey by path structure, not by size

The closing step of `spec` names the next command. A spec that introduces a new screen or route,
lets the actor do more than one thing (more than one path), or walks a path of more than one step
is sent to `journey` before any tickets are cut; every other spec goes straight to `tickets`. The
rule reads the structure of the user stories and never a size word or a story count, so two runs
on the same spec route the same way, and it uses the same definition of a path that `journey` takes
as the unit of its tree.

## Considered options

- Any screen change gets a journey: too broad, a new column on an existing list would get one.
- A story-count threshold: arbitrary, and a long list of one-step stories is not a journey.
- "Large" left to judgment: drifts between sessions and between harnesses.
