# The front-end builder's setup is a Ticket, run by a Playbook of its own

When a Spec reads `Front-end: impeccable` and the project lacks the setup, `tickets` publishes a
**Setup ticket** numbered `00`, and `do` routes it to a `setup` Playbook kept in its own file: no
worktree, no Planner, no Builder, no review. The Playbook shows the exact command of the next
manual step, ends its turn, and on the developer's word runs a check script that proves the step
before it moves on; it refuses `--auto`. The setup is a Ticket, not a precondition `do` checks at
the door of every Front-end ticket, because the session's window is the scarce resource: a door
check would sit in the `ticket` Playbook and be read by every run, and a Ticket pays once, in a run
of its own. This amends ADR 0008, since a second Playbook now takes a chain artifact, and ADR 0057,
since this one Playbook ends a turn on a manual step outside the four Handover classes.

## Considered options

- A precondition checked by script at the door of each Front-end ticket, stopping with
  `Yours: direction`: idempotent and with no ticket kind a run cannot automate, but its text is
  carried by every ticket run.
- A branch inside the `ticket` Playbook for `Kind: setup`: the same cost, plus a Playbook that
  stops only on a Handover class gaining a path that stops at every step.

## Consequences

`tickets` runs the same check script at publish and cuts the Setup ticket only when the setup is
missing, so a second Spec in a project already set up gets none.
