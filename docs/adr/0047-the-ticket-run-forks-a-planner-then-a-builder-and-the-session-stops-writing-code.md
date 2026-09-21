# The ticket run forks a planner, then a builder, and the session stops writing code

`do`'s ticket Playbook held the grounding, the behaviours list and the whole build loop in the
session's own window: `estimate-load.sh` reads 13.4k of ground on a fixed load of 91.5k, with 17k
to 18k more per criterion, so the part that grows with the Ticket is the part the session carried
itself. The run now forks a planner that grounds the Ticket and writes the Plan, then a builder
that runs the build loop in the worktree from that Plan and dispatches its own test authors. The
two are siblings one layer below the session, never a chain, so the test authors stay two layers
below and no step depends on a third. This supersedes, for the ticket Playbook, ADR 0009's rule
that the session writes the production code; the rest of that ADR stands, nesting depth included.

## Considered options

- A planner that forks the builder itself, as one reading of the idea had it: the test authors then
  sit three layers below the session, at the harness default's limit, where the Agent tool is
  withheld whatever the frontmatter says, so the tightest machine is the one that loses the
  delegation.
- A delegate per behaviour, which ADR 0009 weighed and rejected: one round trip per unit for a
  separation the policy loop already gives. The unit here is the Ticket, not the behaviour.
- Keeping the session as the writer and trimming what the loop reads into the window: it caps the
  per-criterion cost and leaves the ground and the reference chain where they are, so the session
  still grows with the Ticket.

## Consequences

The session reads the builder's diff and runs the Gate, the integration, the review and the close,
so nothing reaches the developer's branch that the session did not gate and the review did not
read. Total tokens rise by each fork's own baseline, about 32k, against a session window that no
longer grows with the criteria; ADR 0016 keeps the session's peak as the band a Ticket is sized by,
and the band is now read against the planner's window as well. With the Agent tool withheld, or
with neither agent listed, the session does that work itself, as it already does for the reader.
