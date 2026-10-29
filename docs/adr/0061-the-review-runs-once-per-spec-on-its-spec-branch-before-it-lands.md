# The review runs once per Spec, on its Spec branch, before the branch lands

A `do` ticket run no longer calls `do-code-review`: the Ticket's own Gate is its check before it
lands on the Spec branch (ADR 0060). After each such landing a script's completion check reads
whether every Ticket of the Spec is `resolved`, and the run that finds them all rebases the Spec
branch onto its upstream in the session, then calls `do-code-review` on it with that upstream as
the fixed point, which reviews, fixes and lands it on the developer's branch when Green. The review
reads the local diff, so no pull request is opened for it. This supersedes the "once per run" rule
of ADR 0033 for the ticket Playbook and narrows the Review, which now belongs to a Spec rather than
to one Ticket; the other Playbooks keep one review per run.

## Considered options

- A review per Ticket, as until now: every diff read before it lands, at the price of one reviewer
  fan-out per Ticket and no reviewer ever reading the Spec whole.
- The Spec branch landed first and reviewed after: `Act on` Findings would sit on the developer's
  branch and their fixes land with nothing left to block them.
- A pull request opened for the Spec branch and reviewed there: the same diff the local fixed point
  already gives, behind a remote.

## Consequences

Each run writes its own `resolved` before it runs the completion check, so the last of two
concurrent runs always sees every Ticket resolved, and the final integration is claimed by creating
a file, so two runs that both see it never both integrate. An integration that stops (a contested
hunk unanswered, a review that does not land, `not landed: target moved`) is resumed by a new `do`
on any Ticket of the Spec, whose door takes a `resolved` Ticket whose Spec branch has not landed and
runs only the final integration.

Amended: per ADR 0113, the reasons `mechanics.md` and `final-stopped.md` gave beside the Final
integration and the close live here. The Final integration's tree is the Spec branch in a worktree
of its own, never the run's `do/<slug>` worktree, which the close already removed, and never the main
checkout switched to the Spec branch, which would take the developer's tree from under them and fail
the review's fast-forward. While that tree exists a Ticket of the Spec that lands late reads
`checked-out`, which is the refusal wanted while the Spec is being integrated. Its Loss ledger sits
beside the Spec and never beside a Ticket, and its review token is minted under the tree's slug and
never a Ticket's, since a resume may come through any Ticket of the Spec built in that repository and
must find the same ledger and the same token; the judge's intent is the Spec, since that ledger
spans every Ticket of it. The Post-feature gate and the affected flows run there and not after a
Ticket's landing, since the developer's branch changes only there. On a resume whose `review=` line
names a Review the branch lands through the fix call, since the rebase came after the review, and on
`verdict=land` the Review beside the Spec counts, since the review already read the Spec branch. In
the close, `resolved` is written before the Completion check runs: a run that wrote `resolved` first
is counted by every check that runs after it, so the last of two concurrent runs always sees every
Ticket resolved.

Amended: per ADR 0113, the reasons `ticket.md` gave beside the review token's revokes live here. The
token is revoked before the Builder's fork, since the Builder is the one agent the build step forks
that holds a shell in the worktree: a token still on disk while it builds is a value it could copy
into a marker of its own, and the run after this one would land a branch no reviewer read. Storing
the token out of the worktree is not the guarantee on its own: the window is. A Ticket of a Spec
revokes the Spec's token as well, since a Ticket built and landed after the Spec's Review would
leave that Review counting, and a resume would land the Ticket's commits with no reviewer having
read them. The revoke as soon as the Builder returns closes the window on `built`, `fork`, `stopped`
and a refused return alike, since none of those routes is decided until it has run: a Builder that
ends the run on a `stopped:` reason the session cannot clear, before the review step mints a fresh
token, is the one case the revoke taken before the fork could not close. The guard probe's
`header-only` verdict leaves the `## Sources` check as the whole guard over the fork itself and this
revoke as the guard over its return.
