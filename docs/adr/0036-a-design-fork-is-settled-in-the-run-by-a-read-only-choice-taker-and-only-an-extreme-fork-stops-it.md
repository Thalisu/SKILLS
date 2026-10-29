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

Amended: per ADR 0113, the reasons `forks.md`, `extreme-fork.md` and `change-of-direction.md` gave
beside their rules live here. Neither the Planner nor the Builder rules on a fork it meets: the
Planner holds no tool that writes a Ruling, the Builder's own write guard denies it the Spec, and
an agent that ruled would be ruling a layer below everything that writes a Ruling down, with the
Spec's comments and the door's Rulings never in its hands. The Builder hands both sides back on its
return since it stops its loop on a fork it cannot rule and reads nothing as Extreme on the
session's behalf. An Extreme fork writes nothing to the Spec or the Ticket's criteria, since only a
`settled` Ruling writes either and an Extreme fork has none. A stop that leaves the Ticket `claimed`
writes the `<Ticket>.extreme.md` sidecar so the next `/do` is a resume that stops on the recorded
command and never judges the fork a second time, which could read it the other way; the sidecar's
slots are filled from the stop's own facts and none from the session's wording, so a rerun that
meets the same fork prints the same command. A stop that left nothing claimed writes no sidecar,
since the next `/do` is a first run, which reads no `resume-state.sh`, and a sidecar left there
would outlive the answer `discuss` gives and stop a later resume on a question already settled. The
sidecar is the session's write whichever step found the fork, since the Builder's own write guard
denies every `.scratch/` path. The unruled stop, when no `choice-taker` could be forked, writes no
sidecar, since nothing about the fork says a human must rule on it, so the next `/do` meets the
fork again and forks the `choice-taker` once one can be, rather than stopping on a recorded
command. A change of direction is no fork, since nothing has two sides for a `choice-taker` to rule
between.
