# The setup is committed on the developer's branch before the Spec branch is cut

A Ticket's worktree is cut from the tip of its Spec branch (ADR 0060), so the files the front-end
builder reads (`PRODUCT.md`, `DESIGN.md`, `.impeccable/`) reach a build only when they are
committed. The developer runs the setup in the Main checkout and commits it on their own branch,
with the command `do` gives, and the **Setup ticket** blocks every other Ticket of the Spec, so the
Spec branch is cut from a branch that already carries the setup. The skill and its hooks need no
such care: they belong to the `do` session, which runs in the Main checkout, and its forks inherit
them.

## Considered options

- The setup run in a worktree of the Spec branch and landed there like any Ticket, blocking only
  the Front-end tickets: the Logic tickets start at once, but the developer opens the `init`
  session inside a worktree, the install still happens outside it, and a project-wide setup stays
  tied to one feature until its Final integration.

## Consequences

The Logic tickets wait for the setup, a few minutes of the developer's time once per project. The
commit is the developer's own, since `do-code-review` stays the only lander of their branch.
