# A Ticket lands on its Spec branch, and do lands it there itself

Every Ticket of one Spec now lands on a **Spec branch**, `spec/<feature-slug>`, cut from the
developer's branch by the first `do` run of that Spec and carrying that branch as its local
upstream, and each Ticket's worktree is cut from the Spec branch's tip instead of from HEAD. The
`do` run lands its own Ticket there with a fast-forward under the landing lock of ADR 0043, moved
with `git update-ref`, since the Spec branch is checked out nowhere and `land.sh` only moves the
branch the main checkout is on. This amends ADR 0013 and ADR 0033 for this one branch:
`do-code-review` stays the only lander of the developer's branch, so the reviewer is still the last
thing that reads a diff before it reaches the developer.

## Considered options

- A `land` mode in `do-code-review` with no reviewers, keeping one lander for every branch: the
  mode ADR 0033 already refused as `fix` under a second name, and one fork per Ticket spent on a
  fast-forward.
