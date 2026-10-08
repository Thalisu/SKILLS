# Work found in another repository stops the run, and `tickets` adds to the open feature

A run that finds one of its behaviours needs a change in a repository the **Spec** did not list
stops under the `outward` **Handover class**, at the **Plan** when the **Map** shows it, and writes
the finding into the **Spec**: the missing repository and the behaviour that moved. Its **Reply**
hands over a `tickets` command, and `tickets` gains an additive mode that, on a feature with open
**Tickets**, cuts only what the **Spec** holds and no **Ticket** covers, numbers the new **Tickets**
after the last one, moves the criterion that changed repository and adds the `Blocked by` edge. No
existing **Ticket** is renumbered or deleted, a second call cuts nothing, and nobody edits a file
by hand. The stopped **Ticket** is resumed by a new `do`.

## Considered options

- Pending debt in the **Reply**: the run delivers its half, and the other half is a line of text
  under a **Ticket** marked `resolved` whose criterion cannot pass yet.
- A **Ticket** the developer writes by hand, as ADR 0038 does for a reversed **Ruling**: it works,
  and it is the manual edit this decision removes.
- `discuss` and `spec` opening a new feature for what was missed: `Blocked by` sees one `issues/`
  folder, so the stopped **Ticket** could not name its blocker.

## Consequences

`tickets` no longer stops on every feature that already has open **Tickets**: it stops when the
**Spec** holds nothing they leave uncovered. `discuss` stays the way back when the finding changes
the feature's direction rather than where a piece of it is built.
