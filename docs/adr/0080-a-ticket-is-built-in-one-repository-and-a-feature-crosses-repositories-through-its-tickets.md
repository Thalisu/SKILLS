# A Ticket is built in one repository, and a feature crosses repositories through its Tickets

A feature that touches several services was reaching `do` as one **Ticket** whose behaviours needed
a second repository, where the run had no worktree, branch, **Gate**, **Review** or landing. A
**Ticket** now has exactly one **Build repository**, and a feature that crosses repositories does so
by having several **Tickets** joined by `Blocked by`. Every instrument of a run is bound to one git
object database, so the unit of work follows it rather than each instrument being doubled.

## Considered options

- One run that edits two repositories: it needs a second worktree, **Gate**, **Review** and fixed
  point, plus a landing atomic across repositories, which git does not offer, and whatever it wrote
  in the second repository would sit outside the diff the **Review** reads.
