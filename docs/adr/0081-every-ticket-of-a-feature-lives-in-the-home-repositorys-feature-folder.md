# Every Ticket of a feature lives in the Home repository's Feature folder

A **Spec** that spans repositories lists them, and each **Ticket** names the one it is built in, yet
all of them stay in the **Feature folder** of the **Home repository**, read from a run in another
repository by absolute path. A **Ticket** finds its **Spec** by position, a **Ruling** is written
into that one **Spec** for the next **Ticket** to read (ADR 0037), and `Blocked by` names numbers of
the same `issues/` folder, so one folder keeps all three working across repositories with no new
pointer.

## Considered options

- Each **Ticket** in the **Scratch** of its own **Build repository**: a repository shows the work
  waiting for it, but the **Spec** is either copied per repository, where a **Ruling** made in one
  never reaches the others, or pointed at by a new field, and a blocker in another repository
  needs an address `Blocked by` does not have.

## Consequences

A developer standing in a **Build repository** does not see the **Tickets** that features of other
repositories hold for it. How the list of repositories is written when the **Spec** is an issue on
a remote tracker, where a path on one machine means nothing to a teammate, is not decided.
