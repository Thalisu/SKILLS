# The re-integration retries while the target's tip changes, and has no fixed count

A run whose landing returns `not landed: target moved` integrates again and lands through `fix`,
and it keeps doing so for as long as each attempt meets a new tip of the target. A failure against
the tip the previous attempt already met is not concurrency, and it stops the run as blocked. Every
retry means another landing happened, and concurrent runs are finite, so the loop ends. A fixed
count blocks the first run past it, which is the failure this exists to remove. This supersedes the
rule of ADR 0034 that a second move of the target stops the run.

## Considered options

- A fixed cap of attempts: it bounds the cost of a retry (a **Gate**, and a ledger judge when a
  hunk is contested), and it stops whichever run is one past the cap, however healthy.

## Consequences

The loop's cost grows with the number of runs landing at once: each lost race repeats the run's
integration and its **Gate**. Whether an attempt met a new tip is a script's verdict, never the
session's reading.
