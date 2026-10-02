# One shared script puts a context figure in its band

`.agents/scripts/context-band.sh` takes a figure in tokens and prints `band=small`, `band=medium`
or `band=large`, at the thresholds [ADR 0016](0016-a-ticket-is-sized-by-a-token-estimate-in-three-bands.md)
gives a ticket: small under 150k, medium up to 200k, large beyond. It is the one executable form of
that rule, and the three scripts that print a band call it: `skills/tickets/scripts/estimate.sh`
for the estimate of a slice, `skills/do/scripts/context-usage.sh` for a session's measured peak and
`skills/do/scripts/estimate-load.sh` for a run's projected total. Before this each carried the line
itself, and the third said so in a comment: "Nothing checks the copy". The copies matter because
`tickets` calibrates from the figures `do` measures and folds or splits on the band of its own
estimate, so a threshold changed in one of them would move a ticket between bands on one side of
the chain only, with no test going red.

It sits in `.agents/scripts/`, the home [ADR 0031](0031-a-shared-read-only-script-resolves-a-slug-to-its-feature-folder.md)
opened for a rule more than one skill runs, and a caller reaches it at
`<skill-dir>/../../.agents/scripts/`, the hop the resolver already takes. `scripts/tests/context-band.sh`
carries the thresholds once. The band cases in each caller's own test stay, since they now prove
the caller reaches the shared rule.

A caller that cannot find the script refuses: it names the missing path on stderr and prints no
line on stdout, a band least of all. `estimate.sh` exits 2, `context-usage.sh` exits 5 and
`estimate-load.sh` exits 3, each inside the exit contract it already had. The script is there
whenever the repo is cloned whole, which is how every skill here is installed.

## Considered options

- A fallback copy of the thresholds in each caller, used when the shared script is missing: the
  duplication this removes, kept alive in the one path no test of the shared script reaches.
- `band=unknown` from a caller that cannot find it, the figures still printed: a fourth band value
  that every reader of a `Context:` line and of a breakdown would have to handle, to serve an
  install the repo does not support.
- A file of thresholds each caller sources: the comparison, with its `under` and `up to`, would
  still be written three times, and the boundary is where the copies would drift.
- The rule kept in `skills/do/scripts/` and called by `tickets` by path: one skill reaching into
  another's folder, which `CLAUDE.md` rules out.

## Consequences

On a machine that linked `skills/` without the rest of the repo, a `do` run's context reading
fails, and the resolved ticket carries `Context: not measured` with the script's reason, the line
a failed reading already writes. That ticket is left out of the next calibration. `tickets` cannot
size a slice there at all, and says which script is missing.

A change to the thresholds is one edit, in the shared script and its test, with ADR 0016 amended
beside it.
