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

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the Ticket file's rules live here. The
Ticket is read and edited in its Home repository's main checkout and never on the worktree branch,
since a worktree created from HEAD has no copy of an untracked Ticket, and a claim written in the
main checkout beside an edit of the same file on the branch makes the landing fast-forward fail; one
rule covers the three states, tracked, ignored and untracked. A Ticket built in another repository
is claimed in its Home repository as well, since every run of the feature reads the status there,
and a claim written into the Build repository would leave the Ticket open to a second run. The claim
is written after the grounding, since the grounding is the part of a run that refuses, and a claim
written ahead of it leaves every refusal with a status the developer resets by hand before the
rerun. On the diagnosis-first branch, where the worktree exists before the claim, a refusal removes
the worktree and its branch, so the rerun meets no worktree-exists refusal at the door.
