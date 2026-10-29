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

Amended: per ADR 0113, the reasons `mechanics.md` gave beside the Spec branch live here. A `ticket`
run's worktree starts from the Spec branch, so a Ticket builds on every Ticket that landed before
it, and records it with `--track`, so the close's delete measures the branch against the Spec
branch it landed on. The first run of a Spec is refused while the main checkout is on a protected
branch or on no branch, since that run would cut the Spec branch off the protected branch and record
it as the branch the whole Spec lands on. The landing is a fast-forward of the Spec branch's ref
alone, since the Spec branch is checked out nowhere. A worktree that has it checked out stops the
landing, since a ref moved under a checkout would leave that worktree's index showing the landing as
a reversal, and the run does not switch that checkout itself, since what it holds is the
developer's.
