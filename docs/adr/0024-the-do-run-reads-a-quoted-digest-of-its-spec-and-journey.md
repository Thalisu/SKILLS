# The `do` run reads a quoted Digest of its Spec and journey, never the documents

The `ticket` Playbook's door read the whole Spec and journey on every run, about 21k tokens of them,
to use between 4.0KB and 9.7KB. A forked reader now reads both whole and returns a Digest to the
scratch, quoting the Ticket's journey Path, its numbered stories and its Testing Decisions bullets
with the location of every quote, and the run derives its behaviours from that. It is quoted rather
than paraphrased because the Digest becomes the spec of record for the behaviours step once neither
document enters the thread, and its boundaries are the headings the formats already fix rather than
line ranges only the fork saw.

## Considered options

- Deriving the behaviours from the Ticket's criteria alone, since `ticket-format.md` already cuts
  them from the path's step table and failure branches: it holds on small Tickets and fails on large
  ones, and the 14-criterion Ticket measured here loses the rebase-before-landing rule, the
  review-skip line and the rule that a principle is named only beside a decision.
- A targeted search for the slice instead of a delegate: on that same Ticket a search on its own
  words returns 48 hits in the Spec, most of them in sections the step does not read, still misses
  whole stories and journey steps, and cannot report what it missed.

Amended: per ADR 0113, the reasons `mechanics.md` and `second-run.md` gave beside the reader's rules
live here. The Spec and the journey are read by a fork, since they are two whole documents the run
needs a slice of, the exploration ADR 0009 forks for, and the session never opens them to check the
fork, since every quote comes back with its location and the check reads a quote against its line.
The Digest's `## Sources` lines are the door's own hashes, so the record the reuse gate trusts is the
run's own reading and never the fork's, and a `## Sources` section in the reader's return is dropped,
since a stranger's text can steer the reader into returning one of its own. The door's read of this
Ticket's Ruling lines is the one place they reach the Planner's brief, the Builder's `Rulings:` key
and the Run report, since the Digest carries no Implementation Decisions section; a reused Digest
needs them as much as a fresh one, since a Spec whose hash still matches still carries the Rulings
an earlier run wrote, and a brief without them would bring a settled Design fork back. The reader
runs on the model its definition names, since it quotes rather than designs, and its brief is the
list `digest.md` holds and no second one, since a copy drifts from the brief the fork is handed. A
document that changes while the reader reads it shows nothing in that run, since the door hashed it
before the fork and the next run's comparison finds it moved. A re-forked reader whose return is not
a usable Digest stops the door, since the session writes only from a return it checked.
