# The Ticket file belongs to the main checkout; the worktree never touches it and do never commits it

A local Ticket may be tracked, untracked or ignored by git: `spec` and `tickets` leave `.scratch/`
uncommitted and accept it ignored, so a worktree created from HEAD often does not contain the
Ticket at all, and a claim written into the main checkout before the worktree blocks the closing
fast-forward when the worktree branch edits the same file. So the `ticket` playbook reads and
edits the Ticket in the main checkout only: `claimed` at the start, the ticked criteria, the
appended evidence and `resolved` at the close are file writes there, the `do/<slug>` branch never
touches the file, and `do` never commits it, leaving it for the developer under the same durability
rule `spec` and `tickets` follow; the Review lands beside it in the same place. `do` still commits
its own work in the worktree, one green commit per behaviour, and that branch is what the review
reads. A remote tracker is unchanged: the claim and the close are tracker writes made after the
developer's yes.

## Considered options

- The Ticket edited in the worktree and landed with the code: only works when the Ticket is
  tracked, and the claim then cannot be written before the worktree without blocking the
  fast-forward.
- The Ticket committed alone on the developer's branch with `git add <path>` when tracked, written
  only when not: a truthful history, at the price of two behaviours for one step and a commit made
  outside the worktree.
