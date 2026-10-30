# A Stale ADR stays a norm and a run only records it as Pending debt

When the `do-planner` or the `choice-taker` finds a **Stale ADR**, it reports a `stale-adr:` line, and
only then does the run read a reference of its own for it. The ADR stays a norm, a conflict with the
**Ticket** is a **Design fork** like any other, and otherwise the line goes to the **Pending debt**,
for `/debt` or `/discuss` to settle. A fork that could set an ADR aside on its own reading would hold
the easiest way around any norm, and whether the ADR or the code is wrong is a judgment no run owns.
No other fork detects one, since no other fork of a `do` run opens an ADR.

## Considered options

- The run fixes the ADR itself: an edit outside the **Ticket**'s scope lands on its branch, and an
  unattended run settles which side was right.
- Every fork that explores files reads the ADRs to detect staleness: every run pays that context
  for a case that is rare.
