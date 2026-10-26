# A check red again on its retry is deterministic, and earns a diagnosis fixer, not a stop

ADR 0089 stopped the run when a check its fixer could not reproduce came back red on its one rerun,
handing the developer `fix <check> by hand`. A second identical failure is proof the check was never
a flake, so the run now forks a second `do-pr-fixer` in diagnosis mode, carrying both excerpts, the
job's whole log and the first fixer's return, to bring the stack up, weigh competing hypotheses and
close by ADR 0103's evidence. The fork counts as a round under the three-pushed-round cap, and the run
stops only when that fixer finds no mechanism either, its stop naming each hypothesis it ruled out.
The one rerun stays the cheap triage of a flake ahead of it.

## Considered options

- Straight to diagnosis with no rerun: saves the CI minutes of one retry, and spends a fork with a
  whole stack on every real flake.
