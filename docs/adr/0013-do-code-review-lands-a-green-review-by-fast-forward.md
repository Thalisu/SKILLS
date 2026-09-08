# do-code-review lands a green review by fast-forward; a Review with Act on lands nothing

`do` commits its work in the worktree, one green commit per behaviour, and hands the branch to
`do-code-review`, so the reviewer is the last thing that reads the diff before it reaches the
developer's branch. When the branch it reviewed is not the developer's branch (the `do/<slug>`
worktree branch inside `/do`, the `fix/<slug>` branch after a fix), `do-code-review` lands it: the
developer's branch is fast-forwarded to it when the Review is green, under the landing rules `do`
carried until now (a protected branch refused and named, the branch rebased first when the
developer's branch moved, a failed fast-forward left in place and named, nothing pushed, the reply
ending with the push command). A Review with an `Act on` Finding lands nothing; outside the chain
the landing stays the `fix` run's. A plain review of the branch the developer is on has nothing to
land. This amends ADR 0006 and the `do-code-review` spec: the reviewer still never edits code and
still writes no file but the Review, but it now moves the developer's branch, and `do` no longer
lands. One lander for every reviewed branch, at the price of a reviewer that writes into the
developer's checkout.

## Considered options

- Landing stays with `do`, as ADR 0006 assumed: two landers, one per caller, and the units that
  fix the `Act on` Findings reaching the developer's branch without a second look.
- A second call shaped as a verification, the `fix` run without the fixer, that re-runs only the
  checks the `Act on` Findings named, appends to the Review and lands: cheaper, and it keeps what
  was found and fixed in the file, but a third mode in `do-code-review`.

## Consequences

Inside `/do`, a Review with `Act on` sends each Finding to the build loop as one unit, the gate
re-runs, and `do-code-review` is called again on the same branch; the second Review lands when
green. A second Review with `Act on` stops the run as blocked, with the worktree and its branch
named, for the reason a second deviation from the sketch stops it: the diff is not converging. A
red E2E flow after landing follows the same rule: one unit, the gate, the review, the landing.
Green means no `Act on` Finding and every Axis run; an Axis marked `not run` lands nothing and
goes to the developer; `Consider` never blocks. `do` writes nothing into the Review: the fate of
a Finding is the commit that fixed it, whose body carries the Finding's behaviour line, and the
reply.

ADR 0015 supersedes the Consequences above: the review's own Fixer corrects the `Act on` Findings
for every caller, `do` calls the review once per landing, and a call that returns without landing
stops the run. The landing rules stand.
