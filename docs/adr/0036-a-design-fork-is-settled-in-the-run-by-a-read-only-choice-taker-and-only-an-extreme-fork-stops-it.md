# A design fork is settled in the run by a read-only choice-taker, and only an extreme fork stops it

A `do` run that met a design fork stopped at its step naming `discuss`, the Ticket left `claimed`,
though most forks were already settled by a principle, an ADR or a decision the Spec carried, and
the developer's answer was a confirmation. The `ticket` Playbook now forks the `choice-taker` agent
(`fable`, effort `high`, `Read, Glob, Grep` per ADR 0032) with the two sides: it rules on the norm
the repo writes down when one backs a side, and on the side easiest to undo when none does, and the
session writes the ruling. Only an extreme fork, one whose side weakens a guarantee in a risk class
or cannot be undone once landed, still stops the run, since that is the one boundary
`never-block-on-the-human` keeps for the human.

## Considered options

- A fork with no norm to cite goes to the human: the fork that motivated this change, a typed
  `/sketch` whose reading a commit already held, would still have stopped the run.
- "Too harmful for the AI" judged in the moment: two runs draw the line in two places and no eval
  can grade it, so the test reuses the risk classes the review already puts on a Finding.
- Touching a risk class as the stop test: a Spec about security would stop on every fork, although
  both sides can keep the guarantee whole.

## Consequences

The `design-fork-stops` eval stops expecting a stop on a fork the Spec backs, and a new case covers
the extreme fork that still stops.
