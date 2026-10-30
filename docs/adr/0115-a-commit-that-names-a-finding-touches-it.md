# A commit that names a Finding touches it

`unsettled.sh` held a Finding touched only when a commit since the Review changed the line or range
its header names. That missed fixes already on the branch in three ways, and on a `Caller: do` fix
call, which forks no Fixer, each miss was written `left to the developer, untouched since the
review` beside a commit that fixed it:

- The range was handed to `git log -L` against HEAD, while the Review's numbers are those of its
  `Commit:`. An earlier fix that added or removed lines above a Finding moved the script onto
  another line. The range is now carried to where it sits at HEAD, by the diff from `Commit:`,
  before `git log -L` follows it.
- A Spec Finding's header is a quote from the Spec, so it names no file and no line can be touched.
- A fix that lands at the gate rather than at the sink the header names (a server-side bound on an
  input, a caller that stops trusting it) changes another file.

A commit whose message names the Finding as `Finding <n>` now counts as a touch too. The Fixer
already writes that name in every commit body, and so does a `do` run fixing a Finding. A touch
only buys the re-check: the Finding is settled only when its check is red at the Review's `Commit:`
and green at HEAD, so a commit that names the wrong Finding costs one check run and settles
nothing.

## Considered options

- Fall back to the files the `Fix:` line names: the `Fix:` file is the test the Fixer writes, so a
  new test alone would count as a touch, and a Spec Finding's fix in production code still would
  not.
- Leave the Findings to the developer and ask them to edit the Review: the action a run can take,
  handed over, against
  [never-block-on-the-human](../../.agents/principles/never-block-on-the-human.md).
