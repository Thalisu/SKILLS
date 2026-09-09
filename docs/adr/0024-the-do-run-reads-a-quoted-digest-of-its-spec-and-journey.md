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
