# A ruling reversed after its Ticket landed is built by a new Ticket the developer writes

A developer reads a run's `Rulings` only in the close's reply, after the landing, and `/do` on a
`resolved` Ticket stops, so the edit of a ruling line that ADR 0037 names reaches only the Tickets
not yet built. What already landed is changed by a new Ticket the developer writes by hand in the
ticket format, its criteria taken from the edited line and its `Blocked by` naming every resolved
Ticket that took the old side, and built through the `ticket` Playbook like any other. The ticket
format names it as the one Ticket whose `ready-for-agent` is not written by `tickets`. ADR 0037's
last sentence holds for a run stopped before its close.

## Considered options

- Reopening the resolved Ticket: a backward edge on a status walk that only moves forward, a second
  `Context:` line in the Evidence `tickets` calibrates from, and only that one Ticket's share of a
  ruling every later sibling read.
- The `bug-fix` Playbook: it has no Spec behind it, so the review loses its Spec axis, and code that
  matched the Spec when it landed is a changed decision, not a defect.
- A delta door in `tickets` past its stop on a feature that has Tickets: `.scratch/` is unversioned,
  so no history shows which line changed, and the developer would name the line anyway.
