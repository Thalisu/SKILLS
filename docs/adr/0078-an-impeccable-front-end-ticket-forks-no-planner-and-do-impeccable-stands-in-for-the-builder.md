# An impeccable Front-end ticket forks no Planner, and `do-impeccable` stands in for the Builder

A Front-end ticket of a Spec that reads `Front-end: impeccable` is built by one fork, `do-impeccable`,
an agent definition of this repo that loads the impeccable skill, confines it to the run's worktree,
runs it unattended and code-led, commits once per acceptance criterion and returns what the Builder
returns, so the session's Gate, integration, review and close are unchanged. No Planner is forked:
impeccable reads the project itself and touches no logic, so a Plan's Map would cost a fork nobody
reads. This amends ADR 0047 for this one flow. With no Plan there is no behaviours list, and the
Ticket's own criteria take its place. A Front-end ticket under `Front-end: builder` keeps the
Planner and the Builder.

## Considered options

- Keeping the Planner in front of the new fork: reuse of existing components would be grounded by
  `discover`, at about 32k for a Map impeccable does not build from.
- A `general-purpose` fork briefed by the session on every run: impeccable ships four helper agents
  and none that builds, so the standing rules would be written by the session each time, in the
  window the split exists to spare, and the fork would carry no model pin (ADR 0062).
- The Builder loading the skill itself: impeccable's rules would enter the Builder's references and
  be paid for by every logic run.

## Consequences

`do-impeccable` sits one layer below the session and impeccable's own helpers two, inside the depth
ADR 0047 keeps. Whether the skill honours a root other than the session's working directory is
unproven by its documentation, so the run checks by script that the Main checkout is untouched
after the fork.
