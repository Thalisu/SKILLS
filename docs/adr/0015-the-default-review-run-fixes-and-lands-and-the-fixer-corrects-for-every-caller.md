# The default review run fixes its Act on Findings and lands; the Fixer corrects for every caller, and do calls the review once per landing

A plain `do-code-review` run stopped at the Review and left the fixing to a second human call, or
to `do`'s build loop, so every branch with an `Act on` Finding cost a human read or a second full
review before it could land. Now the default run reviews, forks the Fixer with the `Act on` list,
re-runs each Finding's check and the project's suite, and lands the branch when the Review is
Green, for every caller. `do` no longer turns `Act on` Findings into units of its loop: it reads
the return and calls the review once per landing, one call after the gate and one more per red
E2E flow fixed in the worktree, with the landed commit as the fixed point; a call that returns
without landing stops the run as blocked. The Review is still written before the Fixer runs, as
its input and as the record, and the `## Fix run` section is appended to it; `--no-fix` stops at
the write, and `fix <review>` stays for the developer who edited the file by hand. This reverses
the two-call rule of ADR 0006 and the consequences of ADR 0013, which assumed `Act on` had one
destination, `do`'s loop, and so needed a second review per landing. One fixer, one call and one
lander, at the price of nobody reading the Review before the Fixer acts and of a writer with less
context than the session; both bounded, since the Fixer touches only `Act on` (Rung 3 or above,
with its check named), works in a worktree, and lands by fast-forward with nothing pushed.

## Considered options

- No Review file on the default run, the fixed branch as the run's only output: `do` and a later
  session would have no record of what was judged and what was fixed.
- The Fixer only on the developer's call, with `do` fixing `Act on` as units of its loop and
  calling the review again: the session keeps its context, at the cost of two fixer paths and a
  second full review per landing, the mirror of the two landers ADR 0013 removed.
- `do` landing the fix of a red E2E flow itself: two landers again.

## Consequences

- ADR 0006's rule inside `/do` (an accepted Finding becomes one unit of the build loop) and its
  "the session is the only writer" argument no longer apply to review fixes: the Fixer writes on
  the worktree branch while the run waits on the Skill call, so there is still one writer at a
  time, and the exception list of ADR 0009 gains it.
- The Consequences of ADR 0013 are superseded: no second review per landing and no "second Review
  with `Act on`" rule; what stops the run is a call that returns without landing, for a Finding
  `not fixed` or `not verified`, an Axis `not run`, a red gate after the fix, or a refused landing.
- Depth is unchanged: session, orchestrator, Fixer, test author, the three layers ADR 0006 already
  accepted for the developer's own call.
- The `do-code-review` spec, its journey and its Tickets still describe the two-call model and are
  re-synced by `spec`; the `do` spec was re-synced in the session that wrote this ADR.

[ADR 0033](0033-the-review-runs-once-per-run-and-what-comes-after-it-lands-through-the-gate-alone.md)
supersedes the call per red E2E flow: `do` calls the review once per run, and the fix of a red flow
lands through `fix` on the same Review, the Gate and the landing with no reviewer.
