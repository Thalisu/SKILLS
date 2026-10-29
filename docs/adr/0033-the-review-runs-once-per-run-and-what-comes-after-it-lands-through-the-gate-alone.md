# The review runs once per run, and what comes after it lands through the Gate alone

`do` calls `do-code-review` once per run, with its Fixers, its Gate and its landing. A commit made
after that one call, the fix of a red E2E flow or the hunks a resumed run resolves after
`not landed: target moved`, lands through `do-code-review fix <the Review>`, which forks no reviewer
and runs the Gate and the landing, because a second full review cost the session more tokens than
any other step while the code it read that the first had not is code the Gate already checks. `do`
still never lands.

## Considered options

- A second review call per red flow and after every replay, as ADR 0015 and ADR 0027 had it: every
  commit read by a reviewer, at the price of a second fan-out of two reviewers per run.
- `do` landing the post-review commits itself: two landers again, which ADR 0015 removed.
- A new `land` mode in `do-code-review`: the same Gate and landing that `fix` runs over a settled
  `Act on` list, under a second name.

## Consequences

Commits made after the review reach the developer's branch held to the Gate alone, with no reviewer
reading them. The integration still runs before the review, so a first run's review reads the diff
that lands; only a rebase after the review, on a resumed run, lands hunks no reviewer read. A resumed
run knows the review already ran from the `review=` line of `resume-state.sh`, never from the
session's reading of the thread. This supersedes the "one more per red E2E flow" rule of ADR 0015
and narrows the Consequence of ADR 0027 to the first run.

Amended: per ADR 0113, the reasons `not-landed.md` and `verification.md` gave beside their rules live
here. The review read the branch once, and nothing the run commits after it is read by a reviewer
again, so on the integration after a `not landed: target moved` the reapply check is the only
reading a reapplied block's text gets, and the fix call forks no Fixer and no Gate fixer over code
no reviewer read. The verification runs from the main checkout after the landing, per
`prove-it-works`, since the work is on the developer's branch then and Project facts may say the E2E
stack serves the primary checkout; the worktree stays, since it is where a red flow is fixed. The
flows script prints its `command=` line first, so the verification is a line a reviewer reruns
rather than the run's account of it.
