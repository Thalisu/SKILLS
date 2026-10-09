# A Stretch returns before the session's cache expires, and the branch is the only hand-over

A `do` session waits on its Builder with its whole window idle, and a build that outlasts the
prompt cache's lifetime (one hour on the sessions measured, where a Builder ran for two with 184k
in the session's window) has that window written to the cache again on the turn after the return.
A **Stretch** now carries a time budget below that lifetime: after each behaviour's commit the
Builder checks it, and once it is spent it returns `stopped` with that reason, which the session
clears by forking the next Stretch with the same brief. The same rule holds for `do-impeccable`,
which commits one criterion at a time and is re-forked the same way.

## Considered options

- A hand-over file the Builder writes and returns the path of: a second record of the position
  beside the branch's commits, which `skills/do/references/builder.md` already refuses for the
  brief because the two drift, and a write the Builder's own guard denies under `.scratch/`.
- A thinner session at the wait, so the rewrite is cheaper: it halves the cost of a miss and
  avoids none, where a re-fork costs one fork's baseline, about 32k (ADR 0047).
- A keep-alive turn during the wait: it pays a cached read of the whole window per turn to stay
  idle, and the session has no turn of its own while a fork runs.
- A budget for the Planner and the review as well: neither leaves a checkpoint a re-fork could
  resume from, so stopping one on time throws its work away.

## Consequences

The budget is read between behaviours and never inside one, since a return with uncommitted work
is refused and a partial commit breaks the one commit per behaviour the resume matches on. A
behaviour that outlasts the budget alone is finished, and that miss is accepted. Every Stretch the
budget ends closes at least one behaviour, so a build cannot loop on it. A session whose cache
lives five minutes gains nothing from the budget and pays the re-forks; the budget stays fixed
until such a session is measured.
