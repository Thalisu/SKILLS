# The Ticket reaches the review handed over, and the Review defaults to the main checkout's scratch

A `do` run builds in a linked git worktree created from HEAD, which holds no copy of `.scratch/`,
since git ignores the folder. The review reaches the Ticket, and the Spec beside it, by the
location `do` hands over at its review step, the Ticket's absolute path in the main checkout; the
door resolves what it is given and searches by itself only the tree under review. The one scratch
path the door places on its own, the Review's home when no local Ticket was handed over, is
anchored at the main checkout, the tree its `main_checkout=` line names, so a Review never sits in
a worktree that `git worktree remove` deletes without a word.

## Considered options

The door anchoring every scratch path at the main checkout by itself, finding the Ticket by the
branch's slug there, was built on the branch `feat/anchor-the-scratch-at-the-main-checkout` and
recorded there as ADR 0018; that number stays unused here so the two never collide, and the branch
is kept unmerged, under the tag `archive/anchor-the-scratch-at-the-main-checkout`, as the record
of that design. It lost to the hand-over on two counts. A Ticket matched by name across trees is a
guess the review makes about its caller, where a handed-over location is one string both hold. And
the anchored search had two lookup roots, the main checkout for the scratch and the tree under
review for a tracked spec home, where the hand-over has one.

## Consequences

`do` passes the Ticket's location on every review call, so only a review called with an issue
reference, or with no Ticket at all, writes to the scratch reviews folder, and it writes to the
main checkout's. A plain call from the developer's checkout, where the two trees are one, writes
where it always did. A scratch artifact is never copied into a worktree, per `.agents/scratch.md`.
